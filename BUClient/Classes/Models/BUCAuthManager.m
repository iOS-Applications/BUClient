#import "BUCAuthManager.h"
#import "BUCNetworkEngine.h"
#import "BUCConstants.h"


static NSString *kKeychainItemIdentifer = @"org.bitunion.buc.%@.KeychainUI";


@interface BUCAuthManager ()


// public properties
@property (nonatomic, readwrite) NSString *currentUser;
@property (nonatomic, readwrite) NSString *session;


// global variables
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
+ (BUCAuthManager *)sharedInstance {
    static BUCAuthManager *sharedInstance;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,
                  ^{
                      sharedInstance = [[self alloc] init];
                  });
    
    return sharedInstance;
}


- (id)init {
    self = [super init];
    
    if (self) {
        _currentUser = [[NSUserDefaults standardUserDefaults] stringForKey:BUCCurrentUserDefaultKey];
    }
    
    return self;
}


- (void)loginWithUsername:(NSString *)username
              andPassword:(NSString *)password
                onSuccess:(AuthSuccessBlock)successBlock
                   onFail:(AuthFailBlock)failBlock {
    
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    BUCAuthManager * __weak weakSelf = self;
    NSString *loginURL = @"logging";
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:@"login" forKey:@"action"];
    [json setObject:username forKey:@"username"];
    [json setObject:password forKey:@"password"];
    
    [engine
     fetchDataFromUrl:loginURL
     
     json:json
     
     onResult:^(NSDictionary *resultJSON) {
         NSString *result = [resultJSON objectForKey:@"result"];
         if (![result isEqualToString:@"success"]) {
             failBlock([weakSelf returnFailError]);
             return;
         }
         
         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
         [defaults setObject:username forKey:BUCCurrentUserDefaultKey];
         [defaults setBool:YES forKey:BUCUserLoginStateDefaultKey];
         [defaults synchronize];
         
         weakSelf.currentUser = username;
         weakSelf.session = [resultJSON objectForKey:@"session"];
         [weakSelf setNewPassword:password account:username];
         
         successBlock();
     }
     
     onError:^(NSError *error) {
         failBlock(error);
     }];
}


- (void)updateSessionOnSuccess:(AuthSessionBlock)sessionBlock onFail:(AuthFailBlock)failBlock {
    BUCAuthManager * __weak weakSelf = self;
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:@"login" forKey:@"action"];
    [json setObject:self.currentUser forKey:@"username"];
    [json setObject:[self queryPasswordForAccount:self.currentUser] forKey:@"password"];
    
    [[BUCNetworkEngine sharedInstance]
     
     fetchDataFromUrl:@"logging"
     
     json:json
     
     onResult:^(NSDictionary *resultJSON) {
         NSString *result = [resultJSON objectForKey:@"result"];
         if (![result isEqualToString:@"success"]) {
             failBlock([weakSelf returnFailError]);
             return;
         }
         
         weakSelf.session = [resultJSON objectForKey:@"session"];
         
         sessionBlock();
     }
     
     onError:^(NSError *error) {
         failBlock(error);
     }];
}


#pragma mark - private methods
- (NSError *)returnFailError {
    NSString *failErrorMsg = @"帐号与密码不符，请检查帐号状态";
    NSString *BUCErrorDomain = @"BUClient.ErrorDomain";
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey:failErrorMsg};
        
    return [NSError errorWithDomain:BUCErrorDomain code:1 userInfo:errorInfo];;
}


#pragma mark - key chain stuff
- (void)setNewPassword:(NSString *)password account:(NSString *)account {
    [self setupQueryDicForAccount:account];
    [self resetKeychainItem];
    
    NSMutableDictionary *keychainData = self.keychainData;
    NSString *oldPassword = [keychainData objectForKey:(__bridge id)kSecValueData];
    if (![oldPassword isEqual:password]) {
        [keychainData setObject:account forKey:(__bridge id)kSecAttrAccount];
        [keychainData setObject:password forKey:(__bridge id)kSecValueData];
        [self writeToKeychain];
    }
}


- (NSString *)queryPasswordForAccount:(NSString *)account {
    [self setupQueryDicForAccount:account];
    
    OSStatus keychainErr = noErr;
    CFDictionaryRef outDictionaryCF = nil;
    
    NSDictionary *keychainData = self.keychainData;
    NSDictionary *genericPasswordQuery = self.genericPasswordQuery;
    
    NSDictionary *outDictionary = (__bridge NSDictionary *)outDictionaryCF;
    keychainErr = SecItemCopyMatching((__bridge CFDictionaryRef)genericPasswordQuery, (CFTypeRef *)&outDictionaryCF);
    
    if (keychainErr == noErr) {
        keychainData = [self secItemFormatToDictionary:outDictionary];
        return [keychainData objectForKey:(__bridge id)kSecValueData];
    } else if (keychainErr == errSecItemNotFound) {
        [self resetKeychainItem];
    } else {
        NSAssert(NO, @"Serious error.\n");
    }
    
    return nil;
}


- (void)resetKeychainItem {
    self.keychainData = [[NSMutableDictionary alloc] init];
    
    [self.keychainData setObject:@"BU Account" forKey:(__bridge id)kSecAttrLabel];
    [self.keychainData setObject:@"Login Key" forKey:(__bridge id)kSecAttrDescription];
    [self.keychainData setObject:@"Account" forKey:(__bridge id)kSecAttrAccount];
    [self.keychainData setObject:@"iOS BU Client" forKey:(__bridge id)kSecAttrService];
    [self.keychainData setObject:@"Nothing" forKey:(__bridge id)kSecAttrComment];
    [self.keychainData setObject:@"password" forKey:(__bridge id)kSecValueData];
}


- (void)setupQueryDicForAccount:(NSString *)account {
    self.keychainItemIDString = [NSString stringWithFormat:kKeychainItemIdentifer, account];
    NSData *keychainItemID = [self.keychainItemIDString dataUsingEncoding:NSUTF8StringEncoding];
    
    self.genericPasswordQuery = [[NSMutableDictionary alloc] init];
    [self.genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [self.genericPasswordQuery setObject:keychainItemID forKey:(__bridge id)kSecAttrGeneric];
    [self.genericPasswordQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [self.genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
}


- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert {
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    
    NSData *keychainItemID = [self.keychainItemIDString dataUsingEncoding:NSUTF8StringEncoding];
    
    [returnDictionary setObject:keychainItemID forKey:(__bridge id)kSecAttrGeneric];
    
    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    NSString *passwordString = [dictionaryToConvert objectForKey:(__bridge id)kSecValueData];
    [returnDictionary setObject:[passwordString dataUsingEncoding:NSUTF8StringEncoding]
                         forKey:(__bridge id)kSecValueData];
    
    return returnDictionary;
}


- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert {
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    
    [returnDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    CFDataRef passwordDataCF = NULL;
    OSStatus keychainError = noErr;
    keychainError = SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary, (CFTypeRef *)&passwordDataCF);
    
    NSData *passwordData = (__bridge NSData *)passwordDataCF;
    NSString *password;
    
    if (keychainError == noErr) {
        [returnDictionary removeObjectForKey:(__bridge id)kSecReturnData];
        
        password = [[NSString alloc] initWithBytes:[passwordData bytes]
                                            length:[passwordData length]
                                          encoding:NSUTF8StringEncoding];
        [returnDictionary setObject:password forKey:(__bridge id)kSecValueData];
    } else if (keychainError == errSecItemNotFound) {
        NSAssert(NO, @"Nothing was found in the keychain.\n");
    }
    else {
        NSAssert(NO, @"Serious error.\n");
    }
    
    return returnDictionary;
}


- (void)writeToKeychain {
    CFDictionaryRef attributesCF;
    NSMutableDictionary *updateItem;
    
    if (SecItemCopyMatching((__bridge CFDictionaryRef)self.genericPasswordQuery, (CFTypeRef *)&attributesCF) == noErr) {
        NSMutableDictionary *attributes = (__bridge NSMutableDictionary *)attributesCF;
        updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
        
        [updateItem setObject:[self.genericPasswordQuery objectForKey:(__bridge id)kSecClass]
                       forKey:(__bridge id)kSecClass];
        
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:self.keychainData];
        [tempCheck removeObjectForKey:(__bridge id)kSecClass];
        
        NSAssert(SecItemUpdate((__bridge CFDictionaryRef)updateItem, (__bridge CFDictionaryRef)tempCheck) == noErr,
                 @"Couldn't update the Keychain Item." );
    } else {
        NSAssert(SecItemAdd((__bridge CFDictionaryRef)[self dictionaryToSecItemFormat:self.keychainData], NULL) == noErr,
                 @"Couldn't add the Keychain Item." );
    }
}


@end
