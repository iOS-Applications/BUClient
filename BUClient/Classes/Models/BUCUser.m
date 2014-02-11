//
//  BUCUser.m
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCUser.h"
#import "BUCNetworkEngine.h"
#import <Security/Security.h>

static NSString *kKeychainItemIdentifer = @"org.bitunion.buc.%@.KeychainUI";

@interface BUCUser ()

@property NSString *keychainItemIDString;
@property (nonatomic, strong) NSMutableDictionary *keychainData;
@property (nonatomic, strong) NSMutableDictionary *genericPasswordQuery;

- (void)setupQueryDictionary;
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;
- (void)writeToKeychain;

@end

@implementation BUCUser

@synthesize keychainData, genericPasswordQuery;

#pragma mark - shared singleton object
+(BUCUser *)sharedInstance
{
    static BUCUser *sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
                      sharedInstance = [[self alloc] init];
                  });
    
    return sharedInstance;
}

#pragma mark - init
-(id)init
{
    self = [super init];
    
    if (self) {
        _loginDic = [[NSMutableDictionary alloc] init];
        [_loginDic setObject:@"logging" forKey:@"url"];
        [_loginDic setObject:@"POST" forKey:@"method"];
        _loginDataDic = [[NSMutableDictionary alloc] init];
        [_loginDataDic setObject:@"login" forKey:@"action"];
        [_loginDic setObject:_loginDataDic forKey:@"dataDic"];
        _isLoggedIn = NO;
    }
    
    return self;
}

#pragma mark - public methods
- (void)setNewPassword:(NSString *)newPassword
{
    [self setupQueryDictionary];
    [self resetKeychainItem];
    NSString *oldPassword = [keychainData objectForKey:(__bridge id)kSecValueData];
    if (![oldPassword isEqual:newPassword])
    {
        [keychainData setObject:self.username forKey:(__bridge id)kSecAttrAccount];
        [keychainData setObject:newPassword forKey:(__bridge id)kSecValueData];
        [self writeToKeychain];
    }
}

- (NSString *)getPassword
{
    return [self queryPassword];
}

#pragma mark - private methods
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

-(void)setupQueryDictionary
{
    genericPasswordQuery = [[NSMutableDictionary alloc] init];
    
    [genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword
                             forKey:(__bridge id)kSecClass];
    
    self.keychainItemIDString = [NSString stringWithFormat:kKeychainItemIdentifer, self.username];
    NSData *keychainItemID = [self.keychainItemIDString dataUsingEncoding:NSUTF8StringEncoding];
    [genericPasswordQuery setObject:keychainItemID
                             forKey:(__bridge id)kSecAttrGeneric];
    
    [genericPasswordQuery setObject:(__bridge id)kSecMatchLimitOne
                             forKey:(__bridge id)kSecMatchLimit];
    
    [genericPasswordQuery setObject:(id)kCFBooleanTrue
                             forKey:(__bridge id)kSecReturnAttributes];
}

- (NSString *)queryPassword
{
    [self setupQueryDictionary];
    
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
    
    if (keychainError == noErr)
    {
        [returnDictionary removeObjectForKey:(__bridge id)kSecReturnData];
        
        self.password = [[NSString alloc] initWithBytes:[passwordData bytes]
                                                      length:[passwordData length]
                                                    encoding:NSUTF8StringEncoding];
        [returnDictionary setObject:self.password forKey:(__bridge id)kSecValueData];
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
