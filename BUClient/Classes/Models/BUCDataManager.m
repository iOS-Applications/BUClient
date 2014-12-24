#import "BUCDataManager.h"
#import "BUCNetworkEngine.h"
#import "BUCHTMLScraper.h"
#import "UIImage+BUCImageCategory.h"
#import "BUCModels.h"

static NSString * const BUCUserLoginStateDefaultKey = @"UserIsLoggedIn";

@interface BUCDataManager ()

@property (nonatomic) BUCHTMLScraper *htmlScraper;
@property (nonatomic) BUCNetworkEngine *networkEngine;

@property (nonatomic) NSMutableArray *postList;

@property (nonatomic) NSCache *defaultCache;

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *session;
@property (nonatomic, readwrite) BOOL loggedIn;

@end

@implementation BUCDataManager
#pragma mark - setup
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
        _host = [[NSUserDefaults standardUserDefaults] stringForKey:@"host"];
        if (!_host) {
            _host = @"http://out.bitunion.org";
            [[NSUserDefaults standardUserDefaults] setObject:_host forKey:@"host"];
        }
        _networkEngine = [[BUCNetworkEngine alloc] init];
        _htmlScraper = [[BUCHTMLScraper alloc] init];
        _htmlScraper.dataManager = self;
        _defaultCache = [[NSCache alloc] init];
        _postList = [[NSMutableArray alloc] init];
        for (int i = 0; i < 20; i = i + 1) {
            BUCPost *post = [[BUCPost alloc] init];
            [_postList addObject:post];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userChanged) name:BUCLoginStateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hostChanged) name:BUCHostChangedNotification object:nil];
    }
    
    return self;
}


- (void)userChanged {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.username = [defaults stringForKey:@"username"];
    self.password = [defaults stringForKey:@"password"];
    _loggedIn = [defaults boolForKey:BUCUserLoginStateDefaultKey];
}

- (void)hostChanged {
    _host = [[NSUserDefaults standardUserDefaults] stringForKey:@"host"];
}

#pragma mark - public

- (NSString *)host {
    if (_host) {
        return _host;
    }
    
    [self hostChanged];
    return _host;
}

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


- (void)logout {
    self.loggedIn = NO;
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:BUCUserLoginStateDefaultKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)loginWithUsername:(NSString *)username password:(NSString *)password onSuccess:(BUCVoidBlock)voidBlock onFail:(BUCStringBlock)errorBlock {
    self.username = username;
    self.password = password;
    [self
     updateSessionOnSuccess:^{
         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
         [defaults setObject:username forKey:@"username"];
         [defaults setObject:password forKey:@"password"];
         [defaults setObject:self.uid forKey:@"uid"];
         [defaults setBool:YES forKey:BUCUserLoginStateDefaultKey];
         NSMutableDictionary *userList = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"userList"]];
         if (!userList) {
             userList = [[NSMutableDictionary alloc] init];
         }
         NSMutableDictionary *userSettings = [[NSMutableDictionary alloc] init];
         [userSettings setObject:username forKey:@"username"];
         [userSettings setObject:password forKey:@"password"];
         [userSettings setObject:self.uid forKey:@"uid"];
         
         NSString *userKey = [username lowercaseString];
         [userList setObject:userSettings forKey:userKey];
         [defaults setObject:userList forKey:@"userList"];
         [defaults synchronize];
         self.loggedIn = YES;
         voidBlock();
     }
     onError:errorBlock];
}


- (void)childCountOfForum:(NSString *)fid thread:(NSString *)tid onSuccess:(BUCNumberBlock)numberBlock onError:(BUCStringBlock)errorBlock {
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


- (void)listOfForum:(NSString *)fid from:(NSString *)from to:(NSString *)to onSuccess:(BUCListBlock)listBlock onError:(BUCStringBlock)errorBlock {
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    if (fid) {
        [json setObject:@"thread" forKey:@"action"];
        [json setObject:fid forKey:@"fid"];
        [json setObject:from forKey:@"from"];
        [json setObject:to forKey:@"to"];
        [self loadListFromUrl:@"thread" json:json listType:@"threadlist" onSuccess:listBlock onError:errorBlock];
    } else {
        [self loadListFromUrl:@"home" json:json listType:@"newlist" onSuccess:listBlock onError:errorBlock];
    }
}


- (void)listOfPost:(NSString *)postID from:(NSString *)from to:(NSString *)to onSuccess:(BUCListBlock)listBlock onError:(BUCStringBlock)errorBlock {
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:@"post" forKey:@"action"];
    [json setObject:postID forKey:@"tid"];
    [json setObject:from forKey:@"from"];
    [json setObject:to forKey:@"to"];
    
    [self loadListFromUrl:@"post" json:json listType:@"postlist" onSuccess:listBlock onError:errorBlock];
}


- (void)newPostToForum:(NSString *)fid thread:(NSString *)tid subject:(NSString *)subject content:(NSString *)content attachment:(UIImage *)attachment onSuccess:(BUCStringBlock)stringBlock onError:(BUCStringBlock)errorBlock {
    
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
         dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
         dispatch_async(queue, ^{
             UIImage *image = [UIImage imageWithData:data size:size];
             if (image) {
                 [cache setObject:image forKey:key];
                 imageBlock(image);
             }
         });
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
- (void)updateSessionOnSuccess:(BUCVoidBlock)voidBlock onError:(BUCStringBlock)errorBlock {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    
    [json setObject:@"login" forKey:@"action"];
    [json setObject:self.username forKey:@"username"];
    [json setObject:self.password forKey:@"password"];
    
    [self
     loadJsonFromUrl:@"logging"
     json:json
     attachment:nil
     isForm:NO
     onSuccess:^(NSDictionary *map) {
         self.session = [map objectForKey:@"session"];
         self.uid = [map objectForKey:@"uid"];
         voidBlock();
     }
     onError:errorBlock
     count:0];
}


- (void)loadJsonFromUrl:(NSString *)url json:(NSMutableDictionary *)json attachment:(UIImage *)attachment isForm:(BOOL)isForm onSuccess:(BUCMapBlock)mapBlock onError:(BUCStringBlock)errorBlock count:(NSInteger)count {
    
    if (![url isEqualToString:@"logging"]) {
        if (!self.session) {
            [self
             updateSessionOnSuccess:^{
                 [self loadJsonFromUrl:url json:json attachment:(UIImage *)attachment isForm:(BOOL)isForm onSuccess:mapBlock onError:errorBlock count:count];
             }
             
             onError:errorBlock];
            
            return;
        } else {
            [json setObject:self.username forKey:@"username"];
            [json setObject:self.session forKey:@"session"];
        }
    }

    [self.networkEngine
     fetchJsonFromUrl:url
     json:json
     attachment:attachment
     isForm:isForm
     
     onResult:^(NSDictionary *map) {
         if ([[map objectForKey:@"result"] isEqualToString:@"success"]) {
             mapBlock(map);
         } else if ([[map objectForKey:@"result"] isEqualToString:@"fail"]) {
             NSString *msg = [map objectForKey:@"msg"];
             NSLog(@"ERROR:%@ COUNT:%ld URL:%@", msg, (long)count, url);
             if ([msg isEqualToString:@"IP+logged"] && count <= 1) {
                 self.session = nil;
                 [self loadJsonFromUrl:url json:json attachment:attachment isForm:isForm onSuccess:mapBlock onError:errorBlock count:count + 1];
             } else if ([msg isEqualToString:@"thread_nopermission"]) {
                 errorBlock(@"该帖设置了访问权限，无法访问");
             } else if ([url isEqualToString:@"logging"]) {
                 errorBlock(@"帐号与密码不符，请检查帐号状态");
             } else if ([msg isEqualToString:@"post_sm_isnull"]) {
                 errorBlock(@"发帖失败，请检查内容是否只含有emoj字符");
             } else if ([msg isEqualToString:@"forum+need+password"]) {
                 errorBlock(@"该论坛需要密码才能进入");
             } else {
                 errorBlock(@"未知错误");
             }
         } else {
             errorBlock(@"未知错误");
         }
     }
     
     onError:errorBlock];
}


- (void)loadListFromUrl:(NSString *)url
                   json:(NSMutableDictionary *)json
                listType:(NSString *)listType
              onSuccess:(BUCListBlock)listBlock
                onError:(BUCStringBlock)errorBlock {
    BUCMapBlock block = ^(NSDictionary *map) {
        NSArray *list = [map objectForKey:listType];
        NSUInteger count = list.count;
        [self populateWithList:list count:count listType:listType];
        listBlock(self.postList, count);
    };
    
    [self loadJsonFromUrl:url json:json attachment:nil isForm:NO onSuccess:block onError:errorBlock count:0];
}


- (void)populateWithList:(NSArray *)list count:(NSUInteger)count listType:(NSString *)listType {
    NSDictionary *metaAttributes = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]};

    void(^block)(BUCPost *, NSDictionary *, NSDictionary *);
    
    if ([listType isEqualToString:@"newlist"]) {
        block  = ^(BUCPost *post, NSDictionary *raw, NSDictionary *metaAttributes) {
            [self newListPost:post fromRaw:raw metaAttributes:metaAttributes];
        };
    } else if ([listType isEqualToString:@"threadlist"]) {
        block = ^(BUCPost *post, NSDictionary *raw, NSDictionary *metaAttributes) {
            [self threadListPost:post fromRaw:raw metaAttributes:metaAttributes];
        };
    } else {
        block = ^(BUCPost *post, NSDictionary *raw, NSDictionary *metaAttributes) {
            [self detailListPost:post fromRaw:raw];
        };
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_apply(count, queue, ^(size_t i) {
        BUCPost *post = [self.postList objectAtIndex:i];
        NSDictionary *raw = [list objectAtIndex:i];
        block(post, raw, metaAttributes);
    });
}


- (void)detailListPost:(BUCPost *)post fromRaw:(NSDictionary *)raw {
    NSMutableString *content = [[NSMutableString alloc] init];
    NSString *title = [self urldecode:[raw objectForKey:@"subject"]];
    if (title) {
        title = [NSString stringWithFormat:@"<b>%@</b>\n\n", title];
        [content appendString:title];
    }
    
    NSString *body = [self urldecode:[raw objectForKey:@"message"]];
    if (body) {
        [content appendString:body];
    }
    
    NSString *attachment = [self urldecode:[raw objectForKey:@"attachment"]];
    if (attachment) {
        NSString *filetype = [self urldecode:[raw objectForKey:@"filetype"]];
        if (filetype && [filetype rangeOfString:@"image/"].length > 0) {
            attachment = [NSString stringWithFormat:@"\n\n本帖包含图片附件:\n\n<img src='%@/%@'>", self.host, attachment];
            [content appendString:attachment];
        }
    }
    
    post.content = [self.htmlScraper richTextFromHtml:content];
    post.uid = [raw objectForKey:@"authorid"];
    NSURL *avatarUrl = [self.htmlScraper avatarUrlFromHtml:[self urldecode:[raw objectForKey:@"avatar"]]];
    if (avatarUrl) {
        post.avatar = [[BUCImageAttachment alloc] init];
        post.avatar.url = avatarUrl;
    } else {
        post.avatar = nil;
    }
    post.pid = [raw objectForKey:@"pid"];
    post.tid = [raw objectForKey:@"tid"];
    post.date = [self parseDateline:[raw objectForKey:@"dateline"]];;
    post.user = [self urldecode:[raw objectForKey:@"author"]];
}


- (void)newListPost:(BUCPost *)post fromRaw:(NSDictionary *)raw metaAttributes:(NSDictionary *)metaAttributes {
    post.tid = [raw objectForKey:@"tid"];
    post.user = [self urldecode:[raw objectForKey:@"author"]];
    post.forumName = [self.htmlScraper richTextFromHtml:[self urldecode:[raw objectForKey:@"fname"]] attributes:metaAttributes].richText;
    
    BUCRichText *content = [self.htmlScraper richTextFromHtml:[self urldecode:[[raw objectForKey:@"pname"] stringByAppendingString:@"\n\n"]]];
    
    if (content.richText.length > 2) {
        post.title = [content.richText.string substringToIndex:content.richText.length - 2];
    }
    
    [content.richText appendAttributedString:[[NSAttributedString alloc] initWithString:post.user attributes:metaAttributes]];
    
    NSString *childCount = [raw objectForKey:@"tid_sum"];
    [content.richText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" • %@ 回复 • ", childCount] attributes:metaAttributes]];
    [content.richText appendAttributedString:post.forumName];
    
    post.content = content;
    post.meta = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"最后回复: %@ by %@", [self parseDateline:[self urldecode:[[raw objectForKey:@"lastreply"] objectForKey:@"when"]]], [self urldecode:[[raw objectForKey:@"lastreply"] objectForKey:@"who"]]] attributes:metaAttributes];
}


- (void)threadListPost:(BUCPost *)post fromRaw:(NSDictionary *)raw metaAttributes:(NSDictionary *)metaAttributes {
    post.uid = [raw objectForKey:@"authorid"];
    post.user = [self urldecode:[raw objectForKey:@"author"]];
    post.tid = [raw objectForKey:@"tid"];
    post.date = [self parseDateline:[raw objectForKey:@"dateline"]];
    NSString *html = [self urldecode:[[raw objectForKey:@"subject"] stringByAppendingString:@"\n\n"]];
    BUCRichText *content = [self.htmlScraper richTextFromHtml:html];
    if (!content) {
        // sometimes API can return invalid HTML string....
        content = [[BUCRichText alloc] init];
        content.richText = [[NSMutableAttributedString alloc] initWithString:html attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]}];
    }
    if (content.richText.length > 2) {
        post.title = [content.richText.string substringToIndex:content.richText.length - 2];
    }
    
    [content.richText appendAttributedString:[[NSAttributedString alloc] initWithString:post.user attributes:metaAttributes]];
    
    [content.richText appendAttributedString:[[NSAttributedString alloc] initWithString:[@" • " stringByAppendingString:post.date] attributes:metaAttributes]];
    
    NSString *viewCount = [raw objectForKey:@"views"];
    viewCount = [NSString stringWithFormat:@"%@ 查看", viewCount];
    NSString *childCount = [raw objectForKey:@"replies"];
    childCount = [NSString stringWithFormat:@"%@ 回复", childCount];
    [content.richText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" • %@ | %@", childCount, viewCount] attributes:metaAttributes]];
    post.content = content;
    post.meta = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"最后回复: %@ by %@", [self parseDateline:[raw objectForKey:@"lastpost"]], [self urldecode:[raw objectForKey:@"lastposter"]]] attributes:metaAttributes];
}


#pragma mark - utilies
- (NSString *)urldecode:(NSString *)string {
    if (!string || (id)string == [NSNull null] || string.length == 0) {
        return nil;
    }
    
    return [[string stringByReplacingOccurrencesOfString:@"+" withString:@" "]
            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


- (NSString *)parseDateline:(NSString *)dateline {
    if (!dateline || (id)dateline == [NSNull null] || dateline.length == 0) {
        return nil;
    }
    
    static NSDateFormatter *dateFormatter;
    static NSDateFormatter *parsingFormatter;
    static dispatch_once_t onceEnsure;
    dispatch_once(&onceEnsure, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_Hans_CN"];
        parsingFormatter = [[NSDateFormatter alloc] init];
        [parsingFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    });
    
    NSString *output;
    NSDate *date;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+$" options:NSRegularExpressionCaseInsensitive error:NULL];
    if ([regex numberOfMatchesInString:dateline options:0 range:NSMakeRange(0, dateline.length)] == 0) {
        date = [parsingFormatter dateFromString:dateline];
    } else {
        date = [NSDate dateWithTimeIntervalSince1970:dateline.doubleValue];
    }
    
    NSTimeInterval timeInterval = abs(date.timeIntervalSinceNow);
    if (timeInterval < 60) {
        output = @"刚刚";
    } else if (timeInterval < 60 * 60) {
        output = [NSString stringWithFormat:@"%d 分钟前", (int)timeInterval / 60];
    } else if (timeInterval < 60 * 60 * 24) {
        output = [NSString stringWithFormat:@"%d 小时前", (int)timeInterval / (60 * 60)];
    } else if (timeInterval < 60 * 60 * 24 * 30) {
        output = [NSString stringWithFormat:@"%d 天前", (int)timeInterval / (60 * 60 * 24)];
    } else if (timeInterval < 60 * 60 * 24 * 30 * 12) {
        output = [NSString stringWithFormat:@"%d 个月前", (int)timeInterval / (60 * 60 * 24 * 30)];
    } else {
        output = [dateFormatter stringFromDate:date];
    }
    
    return output;
}


@end



















