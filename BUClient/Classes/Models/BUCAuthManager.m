//
//  BUCAuthManager.m
//  BUClient
//
//  Created by Joe Jeong on 10/20/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCAuthManager.h"
#import "BUCNetworkEngine.h"
#import "NSObject+BUCTools.h"

static NSString *unknownError = @"未知错误";
static NSString *failError = @"登录失败，请检查帐号状态";

static NSString *kKeychainItemIdentifer = @"org.bitunion.buc.%@.KeychainUI";

@interface BUCAuthManager ()

@property (nonatomic, readwrite) BOOL isLoggedIn;
@property (nonatomic, readwrite) NSString *curUser;
@property (nonatomic, readwrite) NSString *session;

@property (nonatomic) NSMutableDictionary *json;


@property NSString *keychainItemIDString;
@property (nonatomic) NSMutableDictionary *keychainData;
@property (nonatomic) NSMutableDictionary *genericPasswordQuery;

- (void)setNewPassword:(NSString *)password account:(NSString *)account;
- (NSString *)queryPasswordForAccount:(NSString *)account;

- (void)setupQueryDicForAccount:(NSString *)account;
- (void)resetKeychainItem;
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;
- (void)writeToKeychain;

@end

@implementation BUCAuthManager

@synthesize keychainData, genericPasswordQuery;

#pragma mark - public methods
+ (BUCAuthManager *)sharedInstance
{
    static BUCAuthManager *sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
                      sharedInstance = [[self alloc] init];
                  });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        _isLoggedIn = [[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"];
        _curUser = [[NSUserDefaults standardUserDefaults] stringForKey:@"curUser"];
        
        _json = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"login", @"action", nil];
    }
    
    return self;
}

- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password onSuccess:(AuthSuccessBlock)successBlock onFail:(AuthFailBlock)failBlock
{
    NSMutableDictionary *queryJSON = self.json;
    [queryJSON setObject:username forKey:@"username"];
    [queryJSON setObject:password forKey:@"password"];
    
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    NSString *url = [NSString stringWithFormat:engine.baseUrl, @"logging"];
    
    NSURLRequest *req = [self requestWithUrl:url json:queryJSON];
    if (!req) {
        failBlock(unknownError);
        return;
    }
    
    BUCAuthManager * __weak weakSelf = self;
    [engine processRequest:req
                  onResult:^(NSDictionary *resultJSON) {
                      NSString *result = [resultJSON objectForKey:@"result"];
                      if (![result isEqualToString:@"success"]) {
                          failBlock(failError);
                          return;
                      }
                      
                      weakSelf.curUser = username;
                      weakSelf.session = [resultJSON objectForKey:@"session"];
                      weakSelf.isLoggedIn = YES;
                      [weakSelf setNewPassword:password account:username];
                      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                      [defaults setObject:username forKey:@"curUser"];
                      [defaults setBool:weakSelf.isLoggedIn forKey:@"isLoggedIn"];
                      [defaults synchronize];
                      successBlock();
                  }
                   onError:^(NSString *errorMsg) {
                       failBlock(errorMsg);
                   }];
    
}

- (void)updateSessionOnSuccess:(AuthSessionBlock)sessionBlock onFail:(AuthFailBlock)failBlock
{
    
}

#pragma mark - key chain stuff
- (void)setNewPassword:(NSString *)password account:(NSString *)account
{
    [self setupQueryDicForAccount:account];
    [self resetKeychainItem];
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
    
    keychainErr = SecItemCopyMatching((__bridge CFDictionaryRef)genericPasswordQuery, (CFTypeRef *)&outDictionaryCF);
    NSDictionary *outDictionary = (__bridge NSDictionary *)outDictionaryCF;
    
    if (keychainErr == noErr) {
        self.keychainData = [self secItemFormatToDictionary:outDictionary];
        return [keychainData objectForKey:(__bridge id)kSecValueData];
    } else if (keychainErr == errSecItemNotFound) {
        [self resetKeychainItem];
    } else {
        NSAssert(NO, @"Serious error.\n");
    }
    
    return nil;
}

- (void)resetKeychainItem
{
    self.keychainData = [[NSMutableDictionary alloc] init];
    
    [keychainData setObject:@"BU account" forKey:(__bridge id)kSecAttrLabel];
    [keychainData setObject:@"username and password" forKey:(__bridge id)kSecAttrDescription];
    [keychainData setObject:@"Account" forKey:(__bridge id)kSecAttrAccount];
    [keychainData setObject:@"iOS BU client" forKey:(__bridge id)kSecAttrService];
    [keychainData setObject:@"Nothing" forKey:(__bridge id)kSecAttrComment];
    [keychainData setObject:@"password" forKey:(__bridge id)kSecValueData];
}

- (void)setupQueryDicForAccount:(NSString *)account
{
    genericPasswordQuery = [[NSMutableDictionary alloc] init];
    
    [genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword
                             forKey:(__bridge id)kSecClass];
    
    self.keychainItemIDString = [NSString stringWithFormat:kKeychainItemIdentifer, account];
    NSData *keychainItemID = [self.keychainItemIDString dataUsingEncoding:NSUTF8StringEncoding];
    [genericPasswordQuery setObject:keychainItemID
                             forKey:(__bridge id)kSecAttrGeneric];
    
    [genericPasswordQuery setObject:(__bridge id)kSecMatchLimitOne
                             forKey:(__bridge id)kSecMatchLimit];
    
    [genericPasswordQuery setObject:(id)kCFBooleanTrue
                             forKey:(__bridge id)kSecReturnAttributes];
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
    else if (keychainError == errSecItemNotFound) {
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
    
    if (SecItemCopyMatching((__bridge CFDictionaryRef)genericPasswordQuery, (CFTypeRef *)&attributesCF) == noErr)
    {
        NSMutableDictionary *attributes = (__bridge NSMutableDictionary *)attributesCF;
        updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
        
        [updateItem setObject:[genericPasswordQuery objectForKey:(__bridge id)kSecClass]
                       forKey:(__bridge id)kSecClass];
        
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:keychainData];
        [tempCheck removeObjectForKey:(__bridge id)kSecClass];
        
        NSAssert(SecItemUpdate((__bridge CFDictionaryRef)updateItem, (__bridge CFDictionaryRef)tempCheck) == noErr,
                 @"Couldn't update the Keychain Item." );
    }
    else
    {
        NSAssert(SecItemAdd((__bridge CFDictionaryRef)[self dictionaryToSecItemFormat:keychainData], NULL) == noErr,
                 @"Couldn't add the Keychain Item." );
    }
}

@end
