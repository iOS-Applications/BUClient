#import "BUCDataManager.h"
#import "BUCNetworkEngine.h"
#import "BUCHTMLScraper.h"
#import "UIImage+BUCImageCategory.h"
#import "BUCModels.h"

static NSString * const BUCJsonNewListKey = @"newlist";
static NSString * const BUCJsonDetailListKey = @"postlist";
static NSString * const BUCJsonForumChildCountKey = @"fid_sum";
static NSString * const BUCJsonPostChildCountKey = @"tid_sum";
static NSString * const BUCJsonFidKey = @"fid";
static NSString * const BUCJsonTidKey = @"tid";
static NSString * const BUCUrlLogin = @"logging";
static NSString * const BUCJsonSessionKey = @"session";
static NSString * const BUCJsonActionKey = @"action";
static NSString * const BUCJsonListFromKey = @"from";
static NSString * const BUCJsonListToKey = @"to";
static NSString * const BUCUserLoginStateDefaultKey = @"UserIsLoggedIn";

@interface BUCDataManager ()

@property (nonatomic) BUCHTMLScraper *htmlScraper;
@property (nonatomic) BUCNetworkEngine *networkEngine;

@property (nonatomic) NSCache *defaultCache;

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *session;
@property (nonatomic, readwrite) BOOL loggedIn;

@property (nonatomic) NSError *loginError;

@end


@implementation BUCDataManager


#pragma mark - global access
+ (BUCDataManager *)sharedInstance {
    static BUCDataManager *sharedInstance;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _networkEngine = [[BUCNetworkEngine alloc] init];
        _htmlScraper = [[BUCHTMLScraper alloc] init];
        _htmlScraper.dataManager = self;
        _defaultCache = [[NSCache alloc] init];
        
        _loginError = [NSError errorWithDomain:@"BUClient.ErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey:@"帐号与密码不符，请检查帐号状态"}];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userChanged) name:@"BUCUserChangedNotification" object:nil];
    }
    
    return self;
}


- (void)userChanged {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.username = [defaults stringForKey:BUCCurrentUserDefaultKey];
    self.password = [defaults stringForKey:BUCUserPasswordDefaultKey];
    _loggedIn = [defaults boolForKey:BUCUserLoginStateDefaultKey];
}

#pragma mark - public methods
- (BOOL)loggedIn {
    if (_loggedIn) {
        return _loggedIn;
    }
    
    [self userChanged];
    
    if (!self.username || !self.password) {
        return NO;
    }
    
    return _loggedIn;
}


- (void)logOut {
    self.loggedIn = NO;
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:BUCUserLoginStateDefaultKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)loginWithUsername:(NSString *)username password:(NSString *)password onSuccess:(BUCVoidBlock)voidBlock onFail:(BUCErrorBlock)errorBlock {
    self.username = username;
    self.password = password;
    BUCDataManager * __weak weakSelf = self;
    
    [self
     updateSessionOnSuccess:^{
         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
         [defaults setObject:username forKey:BUCCurrentUserDefaultKey];
         [defaults setObject:password forKey:BUCUserPasswordDefaultKey];
         [defaults setObject:weakSelf.uid forKey:BUCUidDefaultKey];
         [defaults setBool:YES forKey:BUCUserLoginStateDefaultKey];
         NSMutableDictionary *userList = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:BUCUserListDefaultKey]];
         if (!userList) {
             userList = [[NSMutableDictionary alloc] init];
         }
         NSMutableDictionary *userSettings = [[NSMutableDictionary alloc] init];
         [userSettings setObject:username forKey:BUCUserNameDefaultKey];
         [userSettings setObject:password forKey:BUCUserPasswordDefaultKey];
         [userSettings setObject:weakSelf.uid forKey:BUCUidDefaultKey];
         
         NSString *userKey = [username lowercaseString];
         [userList setObject:userSettings forKey:userKey];
         [defaults setObject:userList forKey:BUCUserListDefaultKey];
         [defaults synchronize];
         weakSelf.loggedIn = YES;
         voidBlock();
     }
     onError:^(NSError *error) {
         errorBlock(error);
     }];
}


- (void)childCountOfForum:(NSString *)fid thread:(NSString *)tid onSuccess:(BUCNumberBlock)numberBlock onError:(BUCErrorBlock)errorBlock {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    
    if (fid) {
        [json setObject:fid forKey:BUCJsonFidKey];
    }
    
    if (tid) {
        [json setObject:tid forKey:BUCJsonTidKey];
    }
    
    [self
     loadJsonFromUrl:@"fid_tid"
     json:json
     onSuccess:^(NSDictionary *map) {
         NSString *count;
         if (fid) {
             count = [map objectForKey:BUCJsonForumChildCountKey];
         } else {
             count = [map objectForKey:BUCJsonPostChildCountKey];
         }
         numberBlock(count.integerValue);
     }
     onError:errorBlock];
}


- (void)listOfForum:(NSString *)fid from:(NSString *)from to:(NSString *)to onSuccess:(BUCListBlock)listBlock onError:(BUCErrorBlock)errorBlock {
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    if (fid) {
        [json setObject:@"thread" forKey:BUCJsonActionKey];
        [json setObject:fid forKey:BUCJsonFidKey];
        [json setObject:from forKey:BUCJsonListFromKey];
        [json setObject:to forKey:BUCJsonListToKey];
        [self loadListFromUrl:@"thread" json:json listKey:@"threadlist" onSuccess:listBlock onError:errorBlock];
    } else {
        [self loadListFromUrl:@"home" json:json listKey:BUCJsonNewListKey onSuccess:listBlock onError:errorBlock];
    }
}


- (void)listOfPost:(NSString *)postID from:(NSString *)from to:(NSString *)to onSuccess:(BUCListBlock)listBlock onError:(BUCErrorBlock)errorBlock {
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:@"post" forKey:BUCJsonActionKey];
    [json setObject:postID forKey:BUCJsonTidKey];
    [json setObject:from forKey:BUCJsonListFromKey];
    [json setObject:to forKey:BUCJsonListToKey];
    
    [self loadListFromUrl:@"post" json:json listKey:BUCJsonDetailListKey onSuccess:listBlock onError:errorBlock];
}


- (void)getImageWithUrl:(NSURL *)url size:(CGSize)size onSuccess:(BUCImageBlock)imageBlock {
    NSString *key = [NSString stringWithFormat:@"%@%@", url.absoluteString, NSStringFromCGSize(size)];
    NSCache *cache = self.defaultCache;
    UIImage *image = [cache objectForKey:key];
    if (image) {
        imageBlock(image);
        return;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [self.networkEngine
     fetchDataFromUrl:request
     
     onResult:^(NSData *data) {
         UIImage *image = [UIImage imageWithData:data size:size];
         if (image) {
             [cache setObject:image forKey:key];
             imageBlock(image);
         }
     }
     
     onError:nil];
}


- (UIImage *)getImageWithPath:(NSString *)path {
    NSCache *cache = self.defaultCache;
    UIImage *image = [cache objectForKey:path];
    if (image) {
        return image;
    } else {
        image = [UIImage imageWithData:[NSData dataWithContentsOfFile:path] size:CGSizeZero];
        if (image) {
            [cache setObject:image forKey:path];
            return image;
        }
    }
    
    return nil;
}


#pragma mark - private methods
- (void)updateSessionOnSuccess:(BUCVoidBlock)voidBlock onError:(BUCErrorBlock)errorBlock {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    
    [json setObject:@"login" forKey:BUCJsonActionKey];
    [json setObject:self.username forKey:BUCUserNameDefaultKey];
    [json setObject:self.password forKey:BUCUserPasswordDefaultKey];
    BUCDataManager * __weak weakSelf = self;
    
    [self
     loadJsonFromUrl:BUCUrlLogin
     json:json
     onSuccess:^(NSDictionary *map) {
         weakSelf.session = [map objectForKey:BUCJsonSessionKey];
         weakSelf.uid = [map objectForKey:BUCUidDefaultKey];
         voidBlock();
     }
     onError:errorBlock];
}


- (void)loadJsonFromUrl:(NSString *)url json:(NSMutableDictionary *)json onSuccess:(BUCMapBlock)mapBlock onError:(BUCErrorBlock)errorBlock {
    BUCDataManager * __weak weakSelf = self;
    
    if (![url isEqualToString:BUCUrlLogin]) {
        if (!self.session) {
            [self
             updateSessionOnSuccess:^{
                 [weakSelf loadJsonFromUrl:url json:json onSuccess:mapBlock onError:errorBlock];
             }
             
             onError:errorBlock];
            
            return;
        } else {
            [json setObject:weakSelf.username forKey:BUCUserNameDefaultKey];
            [json setObject:weakSelf.session forKey:BUCJsonSessionKey];
        }
    }
    
    [self.networkEngine
     fetchJsonFromUrl:url
     json:json
     
     onResult:^(NSDictionary *map) {
         if ([[map objectForKey:@"result"] isEqualToString:@"fail"]) {
             if ([[map objectForKey:@"msg"] isEqualToString:@"thread_nopermission"]) {
                 errorBlock([weakSelf noPermissionError]);
                 goto done;
             } else if ([url isEqualToString:BUCUrlLogin]) {
                 errorBlock(weakSelf.loginError);
                 goto done;
             }
             
             weakSelf.session = nil;
             [weakSelf loadJsonFromUrl:url json:json onSuccess:mapBlock onError:errorBlock];
         done:
             return;
         }
         
         mapBlock(map);
     }
     
     onError:errorBlock];
}


- (void)loadListFromUrl:(NSString *)url
                   json:(NSMutableDictionary *)json
                listKey:(NSString *)listKey
              onSuccess:(BUCListBlock)listBlock
                onError:(BUCErrorBlock)errorBlock {
    
    BUCDataManager * __weak weakSelf = self;
    
    BUCMapBlock block = ^(NSDictionary *map) {
        [weakSelf successListHandler:map listKey:listKey onSuccess:listBlock onError:errorBlock];
    };
    
    [self loadJsonFromUrl:url json:json onSuccess:block onError:errorBlock];
}


- (void)successListHandler:(NSDictionary *)map listKey:(NSString *)listKey onSuccess:(BUCListBlock)listBlock onError:(BUCErrorBlock)errorBlock {
    static NSString * const BUCJsonPostTitleKey = @"subject";
    static NSString * const BUCLastPosterTemplate = @"Last reply: %@by";
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    NSArray *rawList = [map objectForKey:listKey];
    
    for (NSDictionary *rawPost in rawList) {
        BUCPost *post = [[BUCPost alloc] init];
        
        post.pid = [rawPost objectForKey:@"pid"];
        post.tid = [rawPost objectForKey:BUCJsonTidKey];
        post.fid = [rawPost objectForKey:BUCJsonFidKey];
        
        post.fname = [self urldecode:[rawPost objectForKey:@"fname"]];
        
        post.user = [self urldecode:[rawPost objectForKey:@"author"]];
        post.uid = [rawPost objectForKey:@"authorid"];
        
        post.avatar = [self.htmlScraper avatarUrlFromHtml:[self urldecode:[rawPost objectForKey:@"avatar"]]];
        
        
        if ([listKey isEqualToString:BUCJsonNewListKey]) {
            post.title = [self.htmlScraper richTextFromHtml:[self urldecode:[rawPost objectForKey:@"pname"]]];
            NSString *lastPostDateline = [self parseDateline:[self urldecode:[[rawPost objectForKey:@"lastreply"] objectForKey:@"when"]]];
            post.lastPoster = [self urldecode:[[rawPost objectForKey:@"lastreply"] objectForKey:@"who"]];
            post.lastPostDateline = [NSString stringWithFormat:BUCLastPosterTemplate, lastPostDateline];
            NSString *childCount = [rawPost objectForKey:BUCJsonPostChildCountKey];
            if ([childCount isEqualToString:@"1"]) {
                post.statistic = @"• 1 reply •";
            } else {
                post.statistic = [NSString stringWithFormat:@"• %@ replies •", childCount];
            }

        } else if ([listKey isEqualToString:BUCJsonDetailListKey]) {
            NSMutableString *content = [[NSMutableString alloc] init];
            NSString *title = [self urldecode:[rawPost objectForKey:BUCJsonPostTitleKey]];
            if (title) {
                title = [NSString stringWithFormat:@"<b>%@</b>\n\n", title];
                [content appendString:title];
            }
            
            NSString *body = [self urldecode:[rawPost objectForKey:@"message"]];
            if (body) {
                [content appendString:body];
            }
            
            NSString *attachment = [self urldecode:[rawPost objectForKey:@"attachment"]];
            if (attachment) {
                NSString *filetype = [self urldecode:[rawPost objectForKey:@"filetype"]];
                if (filetype && [filetype rangeOfString:@"image/"].length > 0) {
                    attachment = [NSString stringWithFormat:@"\n\n本帖包含图片附件:\n\n<img src='http://out.bitunion.org/%@'>", attachment];
                    [content appendString:attachment];
                }
            }
            
            post.content = [self.htmlScraper richTextFromHtml:content];
        } else {
            post.title = [self.htmlScraper richTextFromHtml:[self urldecode:[rawPost objectForKey:BUCJsonPostTitleKey]]];
            NSString *viewCount = [rawPost objectForKey:@"views"];
            NSString *childCount = [rawPost objectForKey:@"replies"];
            post.statistic = [NSString stringWithFormat:@"• %@/%@", childCount, viewCount];
            NSString *lastPostDateline = [self parseDateline:[rawPost objectForKey:@"lastpost"]];
            post.lastPostDateline = [NSString stringWithFormat:BUCLastPosterTemplate, lastPostDateline];
            post.lastPoster = [self urldecode:[rawPost objectForKey:@"lastposter"]];
        }
        
        post.dateline = [self parseDateline:[rawPost objectForKey:@"dateline"]];
        
        [list addObject:post];
    }
    
    listBlock(list);
}


#pragma mark - utilies
- (NSString *)urldecode:(NSString *)string {
    if (!string || (id)string == [NSNull null] || string.length == 0) {
        return nil;
    }
    
    return [[string stringByReplacingOccurrencesOfString:@"+" withString:@" "]
            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


- (NSError *)noPermissionError {
    return [NSError errorWithDomain:@"BUClient.ErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey:@"该帖设置了访问权限，无法访问"}];;
}


- (NSString *)parseDateline:(NSString *)dateline {
    if (!dateline || (id)dateline == [NSNull null] || dateline.length == 0) {
        return nil;
    }
    
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceEnsure;
    dispatch_once(&onceEnsure, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        
    });
    
    NSString *output;
    NSDate *date;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+$" options:NSRegularExpressionCaseInsensitive error:NULL];
    if ([regex numberOfMatchesInString:dateline options:0 range:NSMakeRange(0, dateline.length)] == 0) {
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        date = [dateFormatter dateFromString:dateline];
    } else {
        date = [NSDate dateWithTimeIntervalSince1970:dateline.doubleValue];
    }
    
    NSTimeInterval timeInterval = abs(date.timeIntervalSinceNow);
    if (timeInterval < 60 * 2) {
        output = @"just now ";
    } else if (timeInterval < 60 * 60 * 2) {
        output = [NSString stringWithFormat:@"%d minutes ago ", (int)timeInterval / 60];
    } else if (timeInterval < 60 * 60 * 24 * 2) {
        output = [NSString stringWithFormat:@"%d hours ago ", (int)timeInterval / (60 * 60)];
    } else if (timeInterval < 60 * 60 * 24 * 30 * 2) {
        output = [NSString stringWithFormat:@"%d days ago ", (int)timeInterval / (60 * 60 * 24)];
    } else if (timeInterval < 60 * 60 * 24 * 30 * 12) {
        output = [NSString stringWithFormat:@"%d months ago ", (int)timeInterval / (60 * 60 * 24 * 30)];
    } else {
        [dateFormatter setDateFormat:@"yyyy/MM/dd "];
        output = [dateFormatter stringFromDate:date];
    }
    
    return output;
}


@end



















