#import "BUCKeyChainWrapper.h"


static NSString *kKeychainItemIdentifer = @"org.bitunion.buc.%@.KeychainUI";


@interface BUCKeyChainWrapper ()

@property (nonatomic) NSMutableDictionary *keychainData;
@property (nonatomic) NSMutableDictionary *genericPasswordQuery;


@end


@implementation BUCKeyChainWrapper
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
    [self.genericPasswordQuery setObject:[[NSString stringWithFormat:kKeychainItemIdentifer, username] dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrGeneric];
    
    CFDataRef resultCF = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)self.genericPasswordQuery, (CFTypeRef *)&resultCF) == noErr) {
        NSData *passwordData = (__bridge NSData *)resultCF;
        if (resultCF) {
            CFRelease(resultCF);
            resultCF = NULL;
        }
        NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
        if (password) {
            return password;
        }
    }
    
    if (resultCF) {
        CFRelease(resultCF);
    }
    
    return nil;
}


- (void)savePassword:(NSString *)password username:(NSString *)username {
    NSData *keychainItemID = [[NSString stringWithFormat:kKeychainItemIdentifer, username] dataUsingEncoding:NSUTF8StringEncoding];
    [self.genericPasswordQuery setObject:keychainItemID forKey:(__bridge id)kSecAttrGeneric];
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
