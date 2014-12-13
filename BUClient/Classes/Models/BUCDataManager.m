#import "BUCDataManager.h"
#import "BUCNetworkEngine.h"
#import "BUCHTMLScraper.h"
#import "UIImage+BUCImageCategory.h"
#import "BUCModels.h"

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
@property (nonatomic) NSError *postError;
@property (nonatomic) NSError *unknownError;

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
        _postError = [NSError errorWithDomain:@"BUClient.ErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey:@"发帖失败，请检查内容是否只含有emoj字符"}];
        _unknownError = [NSError errorWithDomain:@"BUClient.ErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey:@"未知错误"}];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userChanged) name:BUCLoginStateNotification object:nil];
    }
    
    return self;
}


- (void)userChanged {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.username = [defaults stringForKey:@"username"];
    self.password = [defaults stringForKey:@"password"];
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
         [defaults setObject:username forKey:@"username"];
         [defaults setObject:password forKey:@"password"];
         [defaults setObject:weakSelf.uid forKey:@"uid"];
         [defaults setBool:YES forKey:BUCUserLoginStateDefaultKey];
         NSMutableDictionary *userList = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"userList"]];
         if (!userList) {
             userList = [[NSMutableDictionary alloc] init];
         }
         NSMutableDictionary *userSettings = [[NSMutableDictionary alloc] init];
         [userSettings setObject:username forKey:@"username"];
         [userSettings setObject:password forKey:@"password"];
         [userSettings setObject:weakSelf.uid forKey:@"uid"];
         
         NSString *userKey = [username lowercaseString];
         [userList setObject:userSettings forKey:userKey];
         [defaults setObject:userList forKey:@"userList"];
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
        [json setObject:fid forKey:@"fid"];
    }
    
    if (tid) {
        [json setObject:tid forKey:@"tid"];
    }
    
    [self
     loadJsonFromUrl:@"fid_tid"
     json:json
     attachment:nil
     isForm:NO
     
     onSuccess:^(NSDictionary *map) {
         NSString *count;
         if (fid) {
             count = [map objectForKey:@"fid_sum"];
         } else {
             count = [map objectForKey:@"tid_sum"];
         }
         numberBlock(count.integerValue);
     }
     
     onError:errorBlock
     
     count:0];
}


- (void)listOfForum:(NSString *)fid from:(NSString *)from to:(NSString *)to onSuccess:(BUCListBlock)listBlock onError:(BUCErrorBlock)errorBlock {
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    if (fid) {
        [json setObject:@"thread" forKey:@"action"];
        [json setObject:fid forKey:@"fid"];
        [json setObject:from forKey:@"from"];
        [json setObject:to forKey:@"to"];
        [self loadListFromUrl:@"thread" json:json listKey:@"threadlist" onSuccess:listBlock onError:errorBlock];
    } else {
        [self loadListFromUrl:@"home" json:json listKey:@"newlist" onSuccess:listBlock onError:errorBlock];
    }
}


- (void)listOfPost:(NSString *)postID from:(NSString *)from to:(NSString *)to onSuccess:(BUCListBlock)listBlock onError:(BUCErrorBlock)errorBlock {
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:@"post" forKey:@"action"];
    [json setObject:postID forKey:@"tid"];
    [json setObject:from forKey:@"from"];
    [json setObject:to forKey:@"to"];
    
    [self loadListFromUrl:@"post" json:json listKey:@"postlist" onSuccess:listBlock onError:errorBlock];
}


- (void)newPostToForum:(NSString *)fid thread:(NSString *)tid subject:(NSString *)subject content:(NSString *)content attachment:(UIImage *)attachment onSuccess:(BUCStringBlock)stringBlock onError:(BUCErrorBlock)errorBlock {
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    if (subject && subject.length > 0) {
        [json setObject:subject forKey:@"subject"];
    }
    if (content && content.length > 0) {
        [json setObject:content forKey:@"message"];
    }
    if (attachment) {
        [json setObject:@"1" forKey:@"attachment"];
    } else {
        [json setObject:@"0" forKey:@"attachment"];
    }
    if (fid) {
        [json setObject:fid forKey:@"fid"];
        [json setObject:@"newthread" forKey:@"action"];
    }
    
    if (tid) {
        [json setObject:tid forKey:@"tid"];
        [json setObject:@"newreply" forKey:@"action"];
    }
    
    [self
     loadJsonFromUrl:@"newpost"
     json:json
     attachment:attachment
     isForm:YES
     onSuccess:^(NSDictionary *map) {
         NSNumber *tid = [map objectForKey:@"tid"];
         stringBlock(tid.stringValue);
     }
     onError:errorBlock
     count:0];
}


- (void)getImageWithUrl:(NSURL *)url size:(CGSize)size onSuccess:(BUCImageBlock)imageBlock {
    NSString *key = [NSString stringWithFormat:@"%@%@", url.absoluteString, NSStringFromCGSize(size)];
    NSCache *cache = self.defaultCache;
    UIImage *image = [cache objectForKey:key];
    if (image) {
        imageBlock(image);
        return;
    }
    
    [self.networkEngine
     fetchDataFromUrl:[NSURLRequest requestWithURL:url]
     
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
    
    [json setObject:@"login" forKey:@"action"];
    [json setObject:self.username forKey:@"username"];
    [json setObject:self.password forKey:@"password"];
    BUCDataManager * __weak weakSelf = self;
    
    [self
     loadJsonFromUrl:@"logging"
     json:json
     attachment:nil
     isForm:NO
     onSuccess:^(NSDictionary *map) {
         weakSelf.session = [map objectForKey:@"session"];
         weakSelf.uid = [map objectForKey:@"uid"];
         voidBlock();
     }
     onError:errorBlock
     count:0];
}


- (void)loadJsonFromUrl:(NSString *)url json:(NSMutableDictionary *)json attachment:(UIImage *)attachment isForm:(BOOL)isForm onSuccess:(BUCMapBlock)mapBlock onError:(BUCErrorBlock)errorBlock count:(NSInteger)count {
    BUCDataManager * __weak weakSelf = self;
    
    if (![url isEqualToString:@"logging"]) {
        if (!self.session) {
            [self
             updateSessionOnSuccess:^{
                 [weakSelf loadJsonFromUrl:url json:json attachment:(UIImage *)attachment isForm:(BOOL)isForm onSuccess:mapBlock onError:errorBlock count:count];
             }
             
             onError:errorBlock];
            
            return;
        } else {
            [json setObject:weakSelf.username forKey:@"username"];
            [json setObject:weakSelf.session forKey:@"session"];
        }
    }
    
    [self.networkEngine
     fetchJsonFromUrl:url
     json:json
     attachment:attachment
     isForm:isForm
     
     onResult:^(NSDictionary *map) {
         if ([[map objectForKey:@"result"] isEqualToString:@"fail"]) {
             NSString *msg = [map objectForKey:@"msg"];
             if ([msg isEqualToString:@"thread_nopermission"]) {
                 errorBlock([weakSelf noPermissionError]);
                 goto done;
             } else if ([url isEqualToString:@"logging"]) {
                 errorBlock(weakSelf.loginError);
                 goto done;
             } else if ([msg isEqualToString:@"post_sm_isnull"]) {
                 errorBlock(weakSelf.postError);
                 goto done;
             } else if (count > 1) {
                 errorBlock(weakSelf.unknownError);
                 goto done;
             }
             
             weakSelf.session = nil;
             [weakSelf loadJsonFromUrl:url json:json attachment:attachment isForm:isForm onSuccess:mapBlock onError:errorBlock count:count + 1];
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
    
    [self loadJsonFromUrl:url json:json attachment:nil isForm:NO onSuccess:block onError:errorBlock count:0];
}


- (void)successListHandler:(NSDictionary *)map listKey:(NSString *)listKey onSuccess:(BUCListBlock)listBlock onError:(BUCErrorBlock)errorBlock {
    static NSString * const BUCLastPosterTemplate = @"Last reply: %@by";
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    NSArray *rawList = [map objectForKey:listKey];
    
    for (NSDictionary *rawPost in rawList) {
        BUCPost *post = [[BUCPost alloc] init];
        
        post.pid = [rawPost objectForKey:@"pid"];
        post.tid = [rawPost objectForKey:@"tid"];
        post.fid = [rawPost objectForKey:@"fid"];
        
        post.forumName = [self urldecode:[rawPost objectForKey:@"fname"]];
        
        post.user = [self urldecode:[rawPost objectForKey:@"author"]];
        post.uid = [rawPost objectForKey:@"authorid"];
        
        post.avatar = [self.htmlScraper avatarUrlFromHtml:[self urldecode:[rawPost objectForKey:@"avatar"]]];
        
        
        if ([listKey isEqualToString:@"newlist"]) {
            post.title = [self.htmlScraper richTextFromHtml:[self urldecode:[rawPost objectForKey:@"pname"]]];
            NSString *lastPostDateline = [self parseDateline:[self urldecode:[[rawPost objectForKey:@"lastreply"] objectForKey:@"when"]]];
            post.lastPoster = [self urldecode:[[rawPost objectForKey:@"lastreply"] objectForKey:@"who"]];
            post.lastPostDateline = [NSString stringWithFormat:BUCLastPosterTemplate, lastPostDateline];
            NSString *childCount = [rawPost objectForKey:@"tid_sum"];
            if ([childCount isEqualToString:@"1"]) {
                post.statistic = @"• 1 reply •";
            } else {
                post.statistic = [NSString stringWithFormat:@"• %@ replies •", childCount];
            }

        } else if ([listKey isEqualToString:@"postlist"]) {
            NSMutableString *content = [[NSMutableString alloc] init];
            NSString *title = [self urldecode:[rawPost objectForKey:@"subject"]];
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
            post.title = [self.htmlScraper richTextFromHtml:[self urldecode:[rawPost objectForKey:@"subject"]]];
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



















