//
//  BUCAuthManager.m
//  BUClient
//
//  Created by Joe Jeong on 10/20/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCAuthManager.h"
#import "BUCNetworkEngine.h"

// constant string used in this file
static NSString *kKeychainItemIdentifer = @"org.bitunion.buc.%@.KeychainUI";

@interface BUCAuthManager ()

// public properties
@property (nonatomic, readwrite) NSString *curUser;
@property (nonatomic, readwrite) NSString *session;

// states needed to keep
@property (nonatomic) NSString *keychainItemIDString;
@property (nonatomic) NSMutableDictionary *keychainData;
@property (nonatomic) NSMutableDictionary *genericPasswordQuery;

// private methods
- (void)setNewPassword:(NSString *)password account:(NSString *)account;
- (NSString *)queryPasswordForAccount:(NSString *)account;

// key chain stuff
- (void)setupQueryDicForAccount:(NSString *)account;
- (void)resetKeychainItem;
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;
- (void)writeToKeychain;

@end

@implementation BUCAuthManager

#pragma mark - public methods
+ (BUCAuthManager *)sharedInstance
{
    static BUCAuthManager *sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,
                  ^{
                      sharedInstance = [[self alloc] init];
                  });
    
    return sharedInstance;
}

- (void)start
{
    self.curUser = [[NSUserDefaults standardUserDefaults] stringForKey:@"curUser"];
    [self updateSessionOnSuccess:nil onFail:nil];
}

- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password onSuccess:(AuthSuccessBlock)successBlock onFail:(AuthFailBlock)failBlock
{
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    BUCAuthManager * __weak weakSelf = self;
    NSString *loginURL = @"logging";
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:@"login" forKey:@"action"];
    [json setObject:username forKey:@"username"];
    [json setObject:password forKey:@"password"];
    
    [engine
     fetchDataFromURL:loginURL
     
     json:json
     
     onResult:^(NSDictionary *resultJSON)
     {
         NSString *result = [resultJSON objectForKey:@"result"];
         if (![result isEqualToString:@"success"])
         {
             if (failBlock)
             {
                 failBlock([weakSelf returnFailError]);
             }
             return;
         }
         
         weakSelf.curUser = username;
         weakSelf.session = [resultJSON objectForKey:@"session"];
         [weakSelf setNewPassword:password account:username];
         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
         [defaults setObject:username forKey:@"curUser"];
         [defaults setBool:YES forKey:@"isLoggedIn"];
         [defaults synchronize];
         
         // login state changed, post login notification
         NSString *kUserLoginNotification = @"kUserLoginNotification";
         [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoginNotification object:weakSelf];
         
         if (successBlock)
         {
             successBlock();
         }
     }
     
     onError:^(NSError *error)
     {
         if (failBlock)
         {
             failBlock(error);
         }
     }];
}

- (void)updateSessionOnSuccess:(AuthSessionBlock)sessionBlock onFail:(AuthFailBlock)failBlock
{
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    BUCAuthManager * __weak weakSelf = self;
    NSString *loginURL = @"logging";
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:@"login" forKey:@"action"];
    [json setObject:self.curUser forKey:@"username"];
    [json setObject:[self queryPasswordForAccount:self.curUser] forKey:@"password"];
    
    [engine
     fetchDataFromURL:loginURL
     
     json:json
     
     onResult:^(NSDictionary *resultJSON)
     {
         NSString *result = [resultJSON objectForKey:@"result"];
         if (![result isEqualToString:@"success"])
         {
             failBlock([weakSelf returnFailError]);
             return;
         }
         
         weakSelf.session = [resultJSON objectForKey:@"session"];
         
         // login state changed, post login notification
         NSString *kUserLoginNotification = @"kUserLoginNotification";
         [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoginNotification object:weakSelf];

         if (sessionBlock)
         {
             sessionBlock();
         }
     }
     
     onError:^(NSError *error)
     {
         if (failBlock)
         {
             failBlock(error);
         }
     }];
}

- (void)logout
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isLoggedIn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - private methods
- (NSError *)returnFailError
{
    NSString *failErrorMsg = @"帐号与密码不符，请检查帐号状态";
    NSString *BUCErrorDomain = @"BUClient.ErrorDomain";
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey:failErrorMsg};
        
    return [NSError errorWithDomain:BUCErrorDomain code:1 userInfo:errorInfo];;
}

#pragma mark - key chain stuff
- (void)setNewPassword:(NSString *)password account:(NSString *)account
{
    [self setupQueryDicForAccount:account];
    [self resetKeychainItem];
    
    NSMutableDictionary *keychainData = self.keychainData;
    NSString *oldPassword = [keychainData objectForKey:(__bridge id)kSecValueData];
    if (![oldPassword isEqual:password])
    {
        [keychainData setObject:account forKey:(__bridge id)kSecAttrAccount];
        [keychainData setObject:password forKey:(__bridge id)kSecValueData];
        [self writeToKeychain];
    }
}

- (NSString *)queryPasswordForAccount:(NSString *)account
{
    [self setupQueryDicForAccount:account];
    
    OSStatus keychainErr = noErr;
    CFDictionaryRef outDictionaryCF = nil;
    
    NSDictionary *keychainData = self.keychainData;
    NSDictionary *genericPasswordQuery = self.genericPasswordQuery;
    
    NSDictionary *outDictionary = (__bridge NSDictionary *)outDictionaryCF;
    keychainErr = SecItemCopyMatching((__bridge CFDictionaryRef)genericPasswordQuery, (CFTypeRef *)&outDictionaryCF);
    
    if (keychainErr == noErr)
    {
        keychainData = [self secItemFormatToDictionary:outDictionary];
        return [keychainData objectForKey:(__bridge id)kSecValueData];
    }
    else if (keychainErr == errSecItemNotFound)
    {
        [self resetKeychainItem];
    }
    else
    {
        NSAssert(NO, @"Serious error.\n");
    }
    
    return nil;
}

- (void)resetKeychainItem
{
    NSMutableDictionary *keychainData = [[NSMutableDictionary alloc] init];
    
    [keychainData setObject:@"BU account" forKey:(__bridge id)kSecAttrLabel];
    [keychainData setObject:@"username and password" forKey:(__bridge id)kSecAttrDescription];
    [keychainData setObject:@"Account" forKey:(__bridge id)kSecAttrAccount];
    [keychainData setObject:@"iOS BU client" forKey:(__bridge id)kSecAttrService];
    [keychainData setObject:@"Nothing" forKey:(__bridge id)kSecAttrComment];
    [keychainData setObject:@"password" forKey:(__bridge id)kSecValueData];
    
    self.keychainData = keychainData;
}

- (void)setupQueryDicForAccount:(NSString *)account
{
    NSString *KeychainItemIdentifer = kKeychainItemIdentifer;
    
    NSString *keychainItemIDString = [NSString stringWithFormat:KeychainItemIdentifer, account];
    NSData *keychainItemID = [keychainItemIDString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *genericPasswordQuery = [[NSMutableDictionary alloc] init];
    [genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [genericPasswordQuery setObject:keychainItemID forKey:(__bridge id)kSecAttrGeneric];
    [genericPasswordQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    
    self.genericPasswordQuery = genericPasswordQuery;
    self.keychainItemIDString = keychainItemIDString;
}

- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert
{
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    
    NSData *keychainItemID = [self.keychainItemIDString dataUsingEncoding:NSUTF8StringEncoding];
    
    [returnDictionary setObject:keychainItemID forKey:(__bridge id)kSecAttrGeneric];
    
    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    NSString *passwordString = [dictionaryToConvert objectForKey:(__bridge id)kSecValueData];
    [returnDictionary setObject:[passwordString dataUsingEncoding:NSUTF8StringEncoding]
                         forKey:(__bridge id)kSecValueData];
    return returnDictionary;
}

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert
{
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    
    [returnDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    CFDataRef passwordDataCF = NULL;
    OSStatus keychainError = noErr;
    keychainError = SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary, (CFTypeRef *)&passwordDataCF);
    
    NSData *passwordData = (__bridge NSData *)passwordDataCF;
    NSString *password = nil;
    
    if (keychainError == noErr)
    {
        [returnDictionary removeObjectForKey:(__bridge id)kSecReturnData];
        
        password = [[NSString alloc] initWithBytes:[passwordData bytes]
                                            length:[passwordData length]
                                          encoding:NSUTF8StringEncoding];
        [returnDictionary setObject:password forKey:(__bridge id)kSecValueData];
    }
    else if (keychainError == errSecItemNotFound)
    {
        NSAssert(NO, @"Nothing was found in the keychain.\n");
    }
    else
    {
        NSAssert(NO, @"Serious error.\n");
    }
    
    return returnDictionary;
}

- (void)writeToKeychain
{
    CFDictionaryRef attributesCF = nil;
    NSMutableDictionary *updateItem = nil;
    
    if (SecItemCopyMatching((__bridge CFDictionaryRef)self.genericPasswordQuery, (CFTypeRef *)&attributesCF) == noErr)
    {
        NSMutableDictionary *attributes = (__bridge NSMutableDictionary *)attributesCF;
        updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
        
        [updateItem setObject:[self.genericPasswordQuery objectForKey:(__bridge id)kSecClass]
                       forKey:(__bridge id)kSecClass];
        
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:self.keychainData];
        [tempCheck removeObjectForKey:(__bridge id)kSecClass];
        
        NSAssert(SecItemUpdate((__bridge CFDictionaryRef)updateItem, (__bridge CFDictionaryRef)tempCheck) == noErr,
                 @"Couldn't update the Keychain Item." );
    }
    else
    {
        NSAssert(SecItemAdd((__bridge CFDictionaryRef)[self dictionaryToSecItemFormat:self.keychainData], NULL) == noErr,
                 @"Couldn't add the Keychain Item." );
    }
}

@end
