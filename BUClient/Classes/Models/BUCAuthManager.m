#import "BUCAuthManager.h"
#import "BUCNetworkEngine.h"
#import "BUCConstants.h"


static NSString *kKeychainItemIdentifer = @"org.bitunion.buc.%@.KeychainUI";


@interface BUCAuthManager ()


// public properties
@property (nonatomic, readwrite) NSString *currentUser;
@property (nonatomic, readwrite) NSString *password;
@property (nonatomic, readwrite) NSString *session;


// private properties
@property (nonatomic) NSMutableDictionary *json;

@property (nonatomic) NSString *keychainItemIDString;
@property (nonatomic) NSMutableDictionary *keychainData;
@property (nonatomic) NSMutableDictionary *genericPasswordQuery;
@property (nonatomic) NSError *loginError;

@end


@implementation BUCAuthManager

@synthesize password = _password;

#pragma mark - public methods
+ (instancetype)sharedInstance {
    static BUCAuthManager *sharedInstance;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}


- (instancetype)init {
    self = [super init];
    
    if (self) {
        _currentUser = [[NSUserDefaults standardUserDefaults] stringForKey:BUCCurrentUserDefaultKey];
        
        _json = [[NSMutableDictionary alloc] init];
        [_json setObject:@"login" forKey:@"action"];
        
        _genericPasswordQuery = [[NSMutableDictionary alloc] init];
        [_genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [_genericPasswordQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
        [_genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];

        _keychainData = [[NSMutableDictionary alloc] init];
        
        _loginError = [NSError errorWithDomain:@"BUClient.ErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey:@"帐号与密码不符，请检查帐号状态"}];
    }
    
    return self;
}


- (void)loginWithUsername:(NSString *)username
              password:(NSString *)password
                onSuccess:(AuthSuccessBlock)successBlock
                   onFail:(AuthFailBlock)failBlock {
    
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    BUCAuthManager * __weak weakSelf = self;
    
    [self.json setObject:username forKey:@"username"];
    [self.json setObject:password forKey:@"password"];
    
    [engine
     fetchDataFromUrl:@"logging"
     
     json:self.json
     
     onResult:^(NSDictionary *resultJSON) {
         NSString *result = [resultJSON objectForKey:@"result"];
         if (![result isEqualToString:@"success"]) {
             failBlock(weakSelf.loginError);
             return;
         }
         
         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
         [defaults setObject:username forKey:BUCCurrentUserDefaultKey];
         [defaults setBool:YES forKey:BUCUserLoginStateDefaultKey];
         [defaults synchronize];
         
         if (![weakSelf.currentUser isEqualToString:username] || ![weakSelf.password isEqualToString:password]) {
             
             weakSelf.currentUser = username;
             weakSelf.password = password;
         }
         
         weakSelf.session = [resultJSON objectForKey:@"session"];
         
         successBlock();
     }
     
     onError:^(NSError *error) {
         failBlock(error);
     }];
}


- (void)updateSessionOnSuccess:(AuthSuccessBlock)sessionBlock onFail:(AuthFailBlock)failBlock {
    if (!self.password) {
        failBlock(self.loginError);
        return;
    }
    
    BUCAuthManager * __weak weakSelf = self;
    
    [self.json setObject:self.currentUser forKey:@"username"];
    [self.json setObject:self.password forKey:@"password"];
    
    [[BUCNetworkEngine sharedInstance]
     
     fetchDataFromUrl:@"logging"
     
     json:self.json
     
     onResult:^(NSDictionary *resultJSON) {
         NSString *result = [resultJSON objectForKey:@"result"];
         if (![result isEqualToString:@"success"]) {
             failBlock(weakSelf.loginError);
             return;
         }
         
         weakSelf.session = [resultJSON objectForKey:@"session"];
         
         sessionBlock();
     }
     
     onError:^(NSError *error) {
         failBlock(error);
     }];
}


#pragma mark - key chain stuff
- (void)setPassword:(NSString *)password {
    _password = password;
    
    [self setupQuery];
    
    NSData *keychainItemID = [self.keychainItemIDString dataUsingEncoding:NSUTF8StringEncoding];
    [self.keychainData setObject:keychainItemID forKey:(__bridge id)kSecAttrGeneric];
    [self.keychainData setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
    [self writeToKeychain];
}


- (NSString *)password {
    if (_password) {
        return _password;
    }
    
    [self setupQuery];
    CFDataRef resultCF = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)self.genericPasswordQuery, (CFTypeRef *)&resultCF);
    NSData *passwordData = (__bridge NSData *)resultCF;
    _password = [[NSString alloc] initWithBytes:[passwordData bytes] length:[passwordData length] encoding:NSUTF8StringEncoding];
    if (resultCF) {
        CFRelease(resultCF);
    }

    return _password;
}


- (void)setupQuery {
    self.keychainItemIDString = [NSString stringWithFormat:kKeychainItemIdentifer, self.currentUser];
    [self.genericPasswordQuery setObject:[self.keychainItemIDString dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrGeneric];
}


- (void)writeToKeychain {
    CFDataRef resultCF = NULL;
    
    if (SecItemCopyMatching((__bridge CFDictionaryRef)self.genericPasswordQuery, (CFTypeRef *)&resultCF) == noErr) {
        CFRelease(resultCF);
        [self.keychainData removeObjectForKey:(__bridge id)kSecClass];
        SecItemUpdate((__bridge CFDictionaryRef)self.genericPasswordQuery, (__bridge CFDictionaryRef)self.keychainData);
    } else {
        [self.keychainData setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        SecItemAdd((__bridge CFDictionaryRef)self.keychainData, NULL);
    }
    
    if (resultCF) {
        CFRelease(resultCF);
    }
}


@end
