#import "BUCAuthManager.h"


static NSString *kKeychainItemIdentifer = @"org.bitunion.buc.%@.KeychainUI";


@interface BUCAuthManager ()

@property (nonatomic) NSString *keychainItemIDString;
@property (nonatomic) NSMutableDictionary *keychainData;
@property (nonatomic) NSMutableDictionary *genericPasswordQuery;


@end


@implementation BUCAuthManager
#pragma mark - public methods
- (instancetype)init {
    self = [super init];
    
    if (self) {
        _genericPasswordQuery = [[NSMutableDictionary alloc] init];
        [_genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [_genericPasswordQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
        [_genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];

        _keychainData = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}


- (NSString *)getPasswordWithUsername:(NSString *)username {
    self.keychainItemIDString = [NSString stringWithFormat:kKeychainItemIdentifer, username];
    [self.genericPasswordQuery setObject:[self.keychainItemIDString dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrGeneric];
    
    CFDataRef resultCF = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)self.genericPasswordQuery, (CFTypeRef *)&resultCF);
    NSData *passwordData = (__bridge NSData *)resultCF;
    NSString *password = [[NSString alloc] initWithBytes:[passwordData bytes] length:[passwordData length] encoding:NSUTF8StringEncoding];
    if (resultCF) {
        CFRelease(resultCF);
    }
    
    return password;
}


- (void)savePassword:(NSString *)password username:(NSString *)username {
    self.keychainItemIDString = [NSString stringWithFormat:kKeychainItemIdentifer, username];
    [self.genericPasswordQuery setObject:[self.keychainItemIDString dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrGeneric];
    
    NSData *keychainItemID = [self.keychainItemIDString dataUsingEncoding:NSUTF8StringEncoding];
    [self.keychainData setObject:keychainItemID forKey:(__bridge id)kSecAttrGeneric];
    [self.keychainData setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
    [self writeToKeychain];
}

#pragma mark - key chain stuff
- (void)writeToKeychain {
    CFDataRef resultCF = NULL;
    
    if (SecItemCopyMatching((__bridge CFDictionaryRef)self.genericPasswordQuery, (CFTypeRef *)&resultCF) == noErr) {
        CFRelease(resultCF);
        [self.keychainData removeObjectForKey:(__bridge id)kSecClass];
        SecItemUpdate((__bridge CFDictionaryRef)self.genericPasswordQuery, (__bridge CFDictionaryRef)self.keychainData);
        return;
    } else {
        [self.keychainData setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        SecItemAdd((__bridge CFDictionaryRef)self.keychainData, NULL);
    }
    
    if (resultCF) {
        CFRelease(resultCF);
    }
}


@end
