#import "BUCDataManager.h"
#import "BUCNetworkEngine.h"
#import "BUCHTMLScraper.h"
#import "UIImage+BUCImageCategory.h"
#import "BUCModels.h"
#import "BUCKeyChainWrapper.h"

// bu api response json key-value pairs
static NSString * const BUCJsonMessageKey = @"msg";
static NSString * const BUCJsonNoPermission = @"thread_nopermission";
static NSString * const BUCJsonResultKey = @"result";
static NSString * const BUCJsonResultSuccess = @"success";
static NSString * const BUCJsonResultFail = @"fail";

static NSString * const BUCJsonNewListKey = @"newlist";
static NSString * const BUCJsonDetailListKey = @"postlist";
static NSString * const BUCJsonPostListKey = @"threadlist";
static NSString * const BUCJsonForumChildCountKey = @"fid_sum";
static NSString * const BUCJsonPostChildCountKey = @"tid_sum";
static NSString * const BUCJsonForumNameKey = @"fname";
static NSString * const BUCJsonFidKey = @"fid";
static NSString * const BUCJsonTidKey = @"tid";
static NSString * const BUCJsonPidKey = @"pid";
static NSString * const BUCJsonPostNameKey = @"pname";
static NSString * const BUCJsonPostTitleKey = @"subject";
static NSString * const BUCJsonUidKey = @"authorid";
static NSString * const BUCJsonAuthorKey = @"author";
static NSString * const BUCJsonAvatarKey = @"avatar";
static NSString * const BUCJsonLastReplyKey = @"lastreply";
static NSString * const BUCJsonLastReplyDateKey = @"when";
static NSString * const BUCJsonLastReplyUserKey = @"who";
static NSString * const BUCJsonPostContentKey = @"message";
static NSString * const BUCJsonAttachmentKey = @"attachment";
static NSString * const BUCJsonAttachmentTypeKey = @"filetype";
static NSString * const BUCJsonViewCountKey = @"views";
static NSString * const BUCJsonChildCountKey = @"replies";
static NSString * const BUCJsonLastPostDateKey = @"lastpost";
static NSString * const BUCJsonLastPostUserKey = @"lastposter";
static NSString * const BUCJsonDateKey = @"dateline";

// bu api url
static NSString * const BUCUrlLogin = @"logging";
static NSString * const BUCUrlFront = @"home";
static NSString * const BUCUrlPostCount = @"fid_tid";
static NSString * const BUCUrlPostList = @"thread";
static NSString * const BUCUrlPostDetail = @"post";
static NSString * const BUCUrlProfile = @"profile";
static NSString * const BUCUrlNewPost = @"newpost";

// bu api post json key-value pairs
static NSString * const BUCJsonUsernameKey = @"username";
static NSString * const BUCJsonPasswordKey = @"password";
static NSString * const BUCJsonSessionKey = @"session";

static NSString * const BUCJsonActionKey = @"action";

static NSString * const BUCJsonActionLogin = @"login";

static NSString * const BUCJsonActionLogout = @"logout";

static NSString * const BUCJsonActionForum = @"forum";

static NSString * const BUCJsonActionPostList = @"thread";
static NSString * const BUCJsonActionPostDetail = @"post";
static NSString * const BUCJsonListFromKey = @"from";
static NSString * const BUCJsonListToKey = @"to";

static NSString * const BUCJsonActionProfile = @"profile";
static NSString * const BUCJsonProfileUsernameKey = @"queryusername";

static NSString * const BUCJsonActionNewPost = @"newthread";
static NSString * const BUCJsonActionNewReply = @"newreply";


@interface BUCDataManager ()

@property (nonatomic) BUCKeyChainWrapper *authManager;
@property (nonatomic) BUCHTMLScraper *htmlScraper;
@property (nonatomic) BUCNetworkEngine *networkEngine;

@property (nonatomic) NSCache *defaultCache;

@property (nonatomic) NSString *username;
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
        _authManager = [[BUCKeyChainWrapper alloc] init];
        _defaultCache = [[NSCache alloc] init];
        
        _loginError = [NSError errorWithDomain:@"BUClient.ErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey:@"帐号与密码不符，请检查帐号状态"}];
    }
    
    return self;
}

#pragma mark - public methods
- (BOOL)loggedIn {
    if (_loggedIn) {
        return _loggedIn;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.username = [defaults stringForKey:BUCCurrentUserDefaultKey];
    self.password = [self.authManager getPasswordWithUsername:self.username];
    
    if (!self.username || !self.password) {
        return NO;
    }
    
    return [defaults boolForKey:BUCUserLoginStateDefaultKey];
}


-(void)loginWithUsername:(NSString *)username password:(NSString *)password onSuccess:(BUCVoidBlock)voidBlock onFail:(BUCErrorBlock)errorBlock {
    NSString *savedUsername = self.username;
    NSString *savedPassword = self.password;
    self.username = username;
    self.password = password;
    BUCDataManager * __weak weakSelf = self;
    
    [self
     updateSessionOnSuccess:^{
         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
         [defaults setObject:username forKey:BUCCurrentUserDefaultKey];
         [defaults setBool:YES forKey:BUCUserLoginStateDefaultKey];
         [defaults synchronize];
         
         if (![savedUsername isEqualToString:username] || ![savedPassword isEqualToString:password]) {
             [weakSelf.authManager savePassword:password username:username];
         }
         
         weakSelf.loggedIn = YES;
         voidBlock();
     }
     onError:^(NSError *error) {
         weakSelf.username = savedUsername;
         weakSelf.password = savedPassword;
         errorBlock(error);
     }];
}


- (void)listOfFrontOnSuccess:(BUCListBlock)listBlock onError:(BUCErrorBlock)errorBlock {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    
    [self loadListFromUrl:BUCUrlFront json:json listKey:BUCJsonNewListKey onSuccess:listBlock onError:errorBlock];
}


- (void)childCountOfForum:(NSString *)fid post:(NSString *)pid onSuccess:(BUCNumberBlock)numberBlock onError:(BUCErrorBlock)errorBlock {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    
    if (fid) {
        [json setObject:fid forKey:BUCJsonFidKey];
    }
    
    if (pid) {
        [json setObject:pid forKey:BUCJsonTidKey];
    }
    
    [self
     loadJsonFromUrl:BUCUrlPostCount
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
    [json setObject:BUCJsonActionPostList forKey:BUCJsonActionKey];
    [json setObject:fid forKey:BUCJsonFidKey];
    [json setObject:from forKey:BUCJsonListFromKey];
    [json setObject:to forKey:BUCJsonListToKey];
    
    [self loadListFromUrl:BUCUrlPostList json:json listKey:BUCJsonPostListKey onSuccess:listBlock onError:errorBlock];
}


- (void)listOfPost:(NSString *)postID from:(NSString *)from to:(NSString *)to onSuccess:(BUCListBlock)listBlock onError:(BUCErrorBlock)errorBlock {
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:BUCJsonActionPostDetail forKey:BUCJsonActionKey];
    [json setObject:postID forKey:BUCJsonTidKey];
    [json setObject:from forKey:BUCJsonListFromKey];
    [json setObject:to forKey:BUCJsonListToKey];
    
    [self loadListFromUrl:BUCUrlPostDetail json:json listKey:BUCJsonDetailListKey onSuccess:listBlock onError:errorBlock];
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
         }
         imageBlock(image);
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
    
    [json setObject:BUCJsonActionLogin forKey:BUCJsonActionKey];
    [json setObject:self.username forKey:BUCJsonUsernameKey];
    [json setObject:self.password forKey:BUCJsonPasswordKey];
    BUCDataManager * __weak weakSelf = self;
    
    [self
     loadJsonFromUrl:BUCUrlLogin
     json:json
     onSuccess:^(NSDictionary *map) {
         weakSelf.session = [map objectForKey:BUCJsonSessionKey];
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
            [json setObject:weakSelf.username forKey:BUCJsonUsernameKey];
            [json setObject:weakSelf.session forKey:BUCJsonSessionKey];
        }
    }
    
    [self.networkEngine
     fetchJsonFromUrl:url
     json:json
     
     onResult:^(NSDictionary *map) {
         if ([[map objectForKey:BUCJsonResultKey] isEqualToString:BUCJsonResultFail]) {
             if ([[map objectForKey:BUCJsonMessageKey] isEqualToString:BUCJsonNoPermission]) {
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
    static NSString * const BUCPostTitleTemplate = @"<b>%@</b>\n\n";
    static NSString * const BUCPostAttachmentTemplate = @"\n\n本帖包含图片附件:\n\n<img src='http://out.bitunion.org/%@'>";
    static NSString * const BUCImageFileTypePrefix = @"image/";
    static NSString * const BUCLastPosterTemplate = @"最后回复: %@ by";
    static NSString * const BUCPostStaticsTemplate1 = @"• %@回复";
    static NSString * const BUCPostStaticsTemplate2 = @"• %@回复/%@查看";
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    NSArray *rawList = [map objectForKey:listKey];
    
    for (NSDictionary *rawPost in rawList) {
        BUCPost *post = [[BUCPost alloc] init];
        
        post.pid = [rawPost objectForKey:BUCJsonPidKey];
        post.tid = [rawPost objectForKey:BUCJsonTidKey];
        post.fid = [rawPost objectForKey:BUCJsonFidKey];
        
        post.fname = [self urldecode:[rawPost objectForKey:BUCJsonForumNameKey]];
        
        post.user = [self urldecode:[rawPost objectForKey:BUCJsonAuthorKey]];
        post.uid = [rawPost objectForKey:BUCJsonUidKey];
        
        post.avatar = [self.htmlScraper avatarUrlFromHtml:[self urldecode:[rawPost objectForKey:BUCJsonAvatarKey]]];
        
        
        if ([listKey isEqualToString:BUCJsonNewListKey]) {
            post.title = [self.htmlScraper richTextFromHtml:[self urldecode:[rawPost objectForKey:BUCJsonPostNameKey]]];
            NSString *lastPostDateline = [self parseDateline:[self urldecode:[[rawPost objectForKey:BUCJsonLastReplyKey] objectForKey:BUCJsonLastReplyDateKey]]];
            post.lastPoster = [self urldecode:[[rawPost objectForKey:BUCJsonLastReplyKey] objectForKey:BUCJsonLastReplyUserKey]];
            post.lastPostDateline = [NSString stringWithFormat:BUCLastPosterTemplate, lastPostDateline];
            post.statistic = [NSString stringWithFormat:BUCPostStaticsTemplate1, [rawPost objectForKey:BUCJsonPostChildCountKey]];
        } else if ([listKey isEqualToString:BUCJsonDetailListKey]) {
            NSMutableString *content = [[NSMutableString alloc] init];
            NSString *title = [self urldecode:[rawPost objectForKey:BUCJsonPostTitleKey]];
            if (title) {
                title = [NSString stringWithFormat:BUCPostTitleTemplate, title];
                [content appendString:title];
            }
            
            NSString *body = [self urldecode:[rawPost objectForKey:BUCJsonPostContentKey]];
            if (body) {
                [content appendString:body];
            }
            
            NSString *attachment = [self urldecode:[rawPost objectForKey:BUCJsonAttachmentKey]];
            if (attachment) {
                NSString *filetype = [self urldecode:[rawPost objectForKey:BUCJsonAttachmentTypeKey]];
                if (filetype && [filetype rangeOfString:BUCImageFileTypePrefix].length > 0) {
                    attachment = [NSString stringWithFormat:BUCPostAttachmentTemplate, attachment];
                    [content appendString:attachment];
                }
            }
            
            post.content = [self.htmlScraper richTextFromHtml:content];
        } else {
            post.title = [self.htmlScraper richTextFromHtml:[self urldecode:[rawPost objectForKey:BUCJsonPostTitleKey]]];
            NSString *viewCount = [rawPost objectForKey:BUCJsonViewCountKey];
            NSString *childCount = [rawPost objectForKey:BUCJsonChildCountKey];
            post.statistic = [NSString stringWithFormat:BUCPostStaticsTemplate2, childCount, viewCount];
            NSString *lastPostDateline = [self parseDateline:[rawPost objectForKey:BUCJsonLastPostDateKey]];
            post.lastPostDateline = [NSString stringWithFormat:BUCLastPosterTemplate, lastPostDateline];
            post.lastPoster = [self urldecode:[rawPost objectForKey:BUCJsonLastPostUserKey]];
        }
        
        post.dateline = [self parseDateline:[rawPost objectForKey:BUCJsonDateKey]];
        
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
    static NSString * const failErrorMsg = @"该帖设置了访问权限，无法访问";
    static NSString * const BUCErrorDomain = @"BUClient.ErrorDomain";
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey:failErrorMsg};
    
    return [NSError errorWithDomain:BUCErrorDomain code:1 userInfo:errorInfo];;
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
    if (timeInterval <= 60) {
        output = @"刚刚";
    } else if (timeInterval <= 60 * 60) {
        output = [NSString stringWithFormat:@"%d分钟前", (int)timeInterval / 60];
    } else if (timeInterval <= 60 * 60 * 24) {
        output = [NSString stringWithFormat:@"%d小时前", (int)timeInterval / (60 * 60)];
    } else if (timeInterval <= 60 * 60 * 24 * 30) {
        output = [NSString stringWithFormat:@"%d天前", (int)timeInterval / (60 * 60 * 24)];
    } else if (timeInterval <= 60 * 60 * 24 * 30 * 12) {
        output = [NSString stringWithFormat:@"%d个月前", (int)timeInterval / (60 * 60 * 24 * 30)];
    } else {
        [dateFormatter setDateFormat:@"yyyy/MM/dd"];
        output = [dateFormatter stringFromDate:date];
    }
    
    return output;
}


@end



















