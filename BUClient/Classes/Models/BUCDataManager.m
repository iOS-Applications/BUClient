#import "BUCDataManager.h"
#import "BUCNetworkEngine.h"
#import "BUCAuthManager.h"
#import "BUCHTMLScraper.h"
#import "UIImage+animatedGIF.h"
#import "UIImage+SimpleResize.h"
#import "BUCModels.h"

// bu api response json key-value pairs
static NSString * const BUCResponseMessageKey = @"msg";
static NSString * const BUCResponseNoPermission = @"thread_nopermission";
static NSString * const BUCResponseResultKey = @"result";
static NSString * const BUCResponseResultSuccess = @"success";
static NSString * const BUCResponseResultFail = @"fail";

static NSString * const BUCResponseNewListKey = @"newlist";
static NSString * const BUCResponseDetailListKey = @"postlist";
static NSString * const BUCResponseForumListKey = @"threadlist";
static NSString * const BUCResponsePostCountKey = @"fid_sum";
static NSString * const BUCResponsePostChildCountKey = @"tid_sum";
static NSString * const BUCResponseForumNameKey = @"fname";
static NSString * const BUCResponseFidKey = @"fid";
static NSString * const BUCResponsePidKey = @"tid";
static NSString * const BUCResponseChildPidKey = @"pid";
static NSString * const BUCResponseFrontPostTitleKey = @"pname";
static NSString * const BUCResponsePostTitleKey = @"subject";
static NSString * const BUCResponseUidKey = @"authorid";
static NSString * const BUCResponseUsernameKey = @"author";
static NSString * const BUCResponseAvatarKey = @"avatar";
static NSString * const BUCResponseLastReplyKey = @"lastreply";
static NSString * const BUCResponseLastReplyDateKey = @"when";
static NSString * const BUCResponseLastReplyUserKey = @"who";
static NSString * const BUCResponseContentKey = @"message";
static NSString * const BUCResponseAttachmentKey = @"attachment";
static NSString * const BUCResponseAttachmentTypeKey = @"filetype";
static NSString * const BUCResponseViewCountKey = @"views";
static NSString * const BUCResponseChildCountKey = @"replies";
static NSString * const BUCResponseFrontChildCountKey = @"tid_sum";
static NSString * const BUCResponseLastPostDateKey = @"lastpost";
static NSString * const BUCResponseLastPostUserKey = @"lastposter";
static NSString * const BUCResponseDateKey = @"dateline";

// bu api url
static NSString * const BUCLoginUrl = @"logging";
static NSString * const BUCFrontUrl = @"home";
static NSString * const BUCPostCountUrl = @"fid_tid";
static NSString * const BUCPostListUrl = @"thread";
static NSString * const BUCPostDetailUrl = @"post";
static NSString * const BUCProfileUrl = @"profile";
static NSString * const BUCNewPostUrl = @"newpost";
static NSString * const BUCNewReplyUrl = @"newpost";


// bu api post json key-value pairs
static NSString * const BUCJsonActionKey = @"action";
static NSString * const BUCJsonLoginAction = @"login";
static NSString * const BUCJsonPostListAction = @"thread";
static NSString * const BUCJsonPostDetailAction = @"post";
static NSString * const BUCJsonProfileAction = @"profile";
static NSString * const BUCJsonNewPostAction = @"newthread";
static NSString * const BUCJsonNewReplyAction = @"newreply";

static NSString * const BUCJsonUsernameKey = @"username";
static NSString * const BUCJsonPasswordKey = @"password";
static NSString * const BUCJsonSessionKey = @"session";
static NSString * const BUCJsonFidKey = @"fid";
static NSString * const BUCJsonPidKey = @"tid";
static NSString * const BUCJsonListFromKey = @"from";
static NSString * const BUCJsonListToKey = @"to";
static NSString * const BUCJsonProfileUidKey = @"uid";
static NSString * const BUCJsonProfileUsernameKey = @"queryusername";
static NSString * const BUCJsonNewSubjectKey = @"subject";
static NSString * const BUCJsonNewContentKey = @"message";
static NSString * const BUCJsonNewAttachmentKey = @"attachment";

// handy string patterns
static NSString * const BUCPostTitleTemplate = @"<b>%@</b>\n\n";
static NSString * const BUCPostAttachmentTemplate = @"\n\n本帖包含图片附件:\n\n<img src='http://out.bitunion.org/%@'>";
static NSString * const BUCImageFileTypePrefix = @"image/";


@interface BUCDataManager ()


@property (nonatomic) BUCHTMLScraper *htmlScraper;

@property (nonatomic) NSURLCache *imageCache;

@property (nonatomic) NSMutableSet *cachedImageUrlSet;


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

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _htmlScraper = [[BUCHTMLScraper alloc] init];
        _imageCache = [[NSURLCache alloc] initWithMemoryCapacity:16384 diskCapacity:268435456 diskPath:@"/imageCache"];
    }
    
    return self;
}

#pragma mark - public methods
- (void)getFrontListOnSuccess:(ArrayBlock)arrayBlock onError:(ErrorBlock)errorBlock {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    
    [self loadListFromUrl:BUCFrontUrl json:json listKey:BUCResponseNewListKey onSuccess:arrayBlock onError:errorBlock];
}


- (void)getPostCountOfForum:(NSString *)fid post:(NSString *)pid onSuccess:(CountBlock)countBlock onError:(ErrorBlock)errorBlock {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    
    if (fid) {
        [json setObject:fid forKey:BUCJsonFidKey];
    }
    
    if (pid) {
        [json setObject:pid forKey:BUCJsonPidKey];
    }
    
    [self
     loadJsonFromUrl:BUCPostCountUrl
     json:json
     onSuccess:^(NSDictionary *resultJson) {
         NSString *count;
         if (fid) {
             count = [resultJson objectForKey:BUCResponsePostCountKey];
         } else {
             count = [resultJson objectForKey:BUCResponsePostChildCountKey];
         }
         countBlock(count.integerValue);
     }
     onError:errorBlock];
}


- (void)getForumList:(NSString *)fid from:(NSString *)from to:(NSString *)to onSuccess:(ArrayBlock)arrayBlock onError:(ErrorBlock)errorBlock {
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:BUCJsonPostListAction forKey:BUCJsonActionKey];
    [json setObject:fid forKey:BUCJsonFidKey];
    [json setObject:from forKey:BUCJsonListFromKey];
    [json setObject:to forKey:BUCJsonListToKey];
    
    [self loadListFromUrl:BUCPostListUrl json:json listKey:BUCResponseForumListKey onSuccess:arrayBlock onError:errorBlock];
}


- (void)getPost:(NSString *)postID from:(NSString *)from to:(NSString *)to onSuccess:(ArrayBlock)arrayBlock onError:(ErrorBlock)errorBlock {
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:BUCJsonPostDetailAction forKey:BUCJsonActionKey];
    [json setObject:postID forKey:BUCJsonPidKey];
    [json setObject:from forKey:BUCJsonListFromKey];
    [json setObject:to forKey:BUCJsonListToKey];
    
    [self loadListFromUrl:BUCPostDetailUrl json:json listKey:BUCResponseDetailListKey onSuccess:arrayBlock onError:errorBlock];
}


- (void)getImageFromUrl:(NSURL *)url onSuccess:(ImageBlock)imageBlock {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLCache *imageCache = self.imageCache;
    BUCDataManager * __weak weakSelf = self;
    
    void (^methodBlock)(NSData *, NSURLResponse *) = ^(NSData *data, NSURLResponse *response) {
        NSCachedURLResponse *cachedImageResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
        [imageCache storeCachedResponse:cachedImageResponse forRequest:request];

        UIImage *image = [weakSelf imageFromData:data url:url];
        
        if (image) {
            imageBlock(image);
        }
    };
    
    NSCachedURLResponse *cachedResponse = [self.imageCache cachedResponseForRequest:request];
    if (cachedResponse) {
        NSData *imageData = cachedResponse.data;
        UIImage *image = [self imageFromData:imageData url:url];
        if (image) {
            imageBlock(image);
        }
    } else {
        [[BUCNetworkEngine sharedInstance]
         fetchImageFromUrl:request
         
         onResult:methodBlock
         
         onError:nil];
    }
}


#pragma mark - networking
- (void)loadJsonFromUrl:(NSString *)url json:(NSMutableDictionary *)json onSuccess:(JsonBlock)jsonBlock onError:(ErrorBlock)errorBlock {
    BUCDataManager * __weak weakSelf = self;
    BUCAuthManager *authManager = [BUCAuthManager sharedInstance];
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    
    if (!authManager.session) {
        [authManager
         updateSessionOnSuccess:^{
             [weakSelf loadJsonFromUrl:url json:json onSuccess:jsonBlock onError:errorBlock];
         }
         onFail:^(NSError *error) {
             errorBlock(error);
         }];
        
        return;
    }
    
    [json setObject:authManager.currentUser forKey:BUCJsonUsernameKey];
    [json setObject:authManager.session forKey:BUCJsonSessionKey];
    
    [engine
     fetchDataFromUrl:url
     json:json
     
     onResult:^(NSDictionary *resultJson) {
         if ([[resultJson objectForKey:BUCResponseResultKey] isEqualToString:BUCResponseResultFail]) {
             if ([[resultJson objectForKey:BUCResponseMessageKey] isEqualToString:BUCResponseNoPermission]) {
                 errorBlock([self noPermissionError]);
                 return;
             }
             
             [authManager
              updateSessionOnSuccess:^(void) {
                  [weakSelf loadJsonFromUrl:url json:json onSuccess:jsonBlock onError:errorBlock];
              }
              
              onFail:^(NSError *error) {
                  errorBlock(error);
              }];
             
             return;
         }
         
         jsonBlock(resultJson);
     }
     
     onError:errorBlock];
}


- (void)loadListFromUrl:(NSString *)url
                   json:(NSMutableDictionary *)json
                listKey:(NSString *)listKey
              onSuccess:(ArrayBlock)arrayBlock
                onError:(ErrorBlock)errorBlock {
    
    BUCDataManager * __weak weakSelf = self;
    
    JsonBlock jsonBlock = ^(NSDictionary *resultJson) {
        [weakSelf successListHandler:resultJson listKey:listKey onSuccess:arrayBlock onError:errorBlock];
    };
    
    [self loadJsonFromUrl:url json:json onSuccess:jsonBlock onError:errorBlock];
}


- (void)successListHandler:(NSDictionary *)resultJson listKey:(NSString *)listKey onSuccess:(ArrayBlock)arrayBlock onError:(ErrorBlock)errorBlock {
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    NSArray *rawArray = [resultJson objectForKey:listKey];
    
    for (NSDictionary *rawDic in rawArray) {
        BUCPost *post = [[BUCPost alloc] init];
        
        post.pid = [rawDic objectForKey:BUCJsonPidKey];
        post.fid = [rawDic objectForKey:BUCJsonFidKey];
        
        post.fname = [self urldecode:[rawDic objectForKey:BUCResponseForumNameKey]];
        
        post.user = [self urldecode:[rawDic objectForKey:BUCResponseUsernameKey]];
        post.uid = [rawDic objectForKey:BUCResponseUidKey];
        
        post.avatar = [self.htmlScraper avatarUrlFromHtml:[self urldecode:[rawDic objectForKey:BUCResponseAvatarKey]]];
        

        if ([listKey isEqualToString:BUCResponseNewListKey]) {
            post.title = [self.htmlScraper richTextFromHtml:[self urldecode:[rawDic objectForKey:BUCResponseFrontPostTitleKey]]];
            NSString *lastPostDateline = [self parseDateline:[self urldecode:[[rawDic objectForKey:BUCResponseLastReplyKey] objectForKey:BUCResponseLastReplyDateKey]]];
            post.lastPoster = [self urldecode:[[rawDic objectForKey:BUCResponseLastReplyKey] objectForKey:BUCResponseLastReplyUserKey]];
            post.lastPostDateline = [NSString stringWithFormat:@"最后回复: %@ by", lastPostDateline];
            post.statistic = [NSString stringWithFormat:@"• %@回复", [rawDic objectForKey:BUCResponseFrontChildCountKey]];
        } else if ([listKey isEqualToString:BUCResponseDetailListKey]) {
            NSMutableString *content = [[NSMutableString alloc] init];
            NSString *title = [self urldecode:[rawDic objectForKey:BUCResponsePostTitleKey]];
            if (title) {
                title = [NSString stringWithFormat:BUCPostTitleTemplate, title];
                [content appendString:title];
            }
            
            NSString *body = [self urldecode:[rawDic objectForKey:BUCResponseContentKey]];
            if (body) {
                [content appendString:body];
            }
            
            NSString *attachment = [self urldecode:[rawDic objectForKey:BUCResponseAttachmentKey]];
            if (attachment) {
                NSString *filetype = [self urldecode:[rawDic objectForKey:BUCResponseAttachmentTypeKey]];
                if (filetype && [filetype rangeOfString:BUCImageFileTypePrefix].length > 0) {
                    attachment = [NSString stringWithFormat:BUCPostAttachmentTemplate, attachment];
                    [content appendString:attachment];
                }
            }
            
            post.content = [self.htmlScraper richTextFromHtml:content];
        } else {
            post.title = [self.htmlScraper richTextFromHtml:[self urldecode:[rawDic objectForKey:BUCResponsePostTitleKey]]];
            NSString *viewCount = [rawDic objectForKey:BUCResponseViewCountKey];
            NSString *childCount = [rawDic objectForKey:BUCResponseChildCountKey];
            post.statistic = [NSString stringWithFormat:@"• %@回复/%@查看", childCount, viewCount];
            NSString *lastPostDateline = [self parseDateline:[rawDic objectForKey:BUCResponseLastPostDateKey]];
            post.lastPostDateline = [NSString stringWithFormat:@"最后回复: %@ by", lastPostDateline];
            post.lastPoster = [self urldecode:[rawDic objectForKey:BUCResponseLastPostUserKey]];
        }
        
        post.dateline = [self parseDateline:[rawDic objectForKey:BUCResponseDateKey]];
        
        [list addObject:post];
    }
    
    arrayBlock(list);
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
    NSString *failErrorMsg = @"该帖设置了访问权限，无法访问";
    NSString *BUCErrorDomain = @"BUClient.ErrorDomain";
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


- (UIImage *)imageFromData:(NSData *)data url:(NSURL *)url {
    UIImage *image;
    
    if ([[url pathExtension] isEqualToString:@"gif"]) {
        image = [UIImage animatedImageWithAnimatedGIFData:data];
    } else {
        image = [UIImage imageWithData:data];
    }
    
    return image;
}


@end



















