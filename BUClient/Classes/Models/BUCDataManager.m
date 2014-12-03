#import "BUCDataManager.h"
#import "BUCNetworkEngine.h"
#import "BUCHTMLScraper.h"
#import "UIImage+animatedGIF.h"
#import "BUCModels.h"
#import <ImageIO/ImageIO.h>

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

// handy string patterns
static NSString * const BUCPostTitleTemplate = @"<b>%@</b>\n\n";
static NSString * const BUCPostAttachmentTemplate = @"\n\n本帖包含图片附件:\n\n<img src='http://out.bitunion.org/%@'>";
static NSString * const BUCImageFileTypePrefix = @"image/";


@interface BUCDataManager ()


@property (nonatomic) BUCHTMLScraper *htmlScraper;


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
        _htmlScraper = [[BUCHTMLScraper alloc] init];
        _authManager = [[BUCAuthManager alloc] init];
        _imageManager = [[BUCImageManager alloc] init];
    }
    
    return self;
}

#pragma mark - public methods
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


- (void)getThumbnailFromUrl:(NSURL *)url onSuccess:(BUCImageBlock)imageBlock {
    
}


- (void)getImageFromUrl:(NSURL *)url size:(CGSize)size onSuccess:(BUCImageBlock)imageBlock {
    
}


- (void)getImageFromUrl:(NSURL *)url onSuccess:(BUCImageBlock)imageBlock {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    BUCDataManager * __weak weakSelf = self;
    
    [[BUCNetworkEngine sharedInstance]
     fetchImageFromUrl:request
     
     onResult:^(NSData *data) {
         imageBlock([weakSelf imageFromData:data url:url]);
     }
     
     onError:nil];
}


#pragma mark - networking
- (void)loadJsonFromUrl:(NSString *)url json:(NSMutableDictionary *)json onSuccess:(BUCMapBlock)mapBlock onError:(BUCErrorBlock)errorBlock {
    BUCDataManager * __weak weakSelf = self;
    BUCAuthManager *authManager = self.authManager;
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    
    if (!authManager.session) {
        [authManager
         updateSessionOnSuccess:^{
             [weakSelf loadJsonFromUrl:url json:json onSuccess:mapBlock onError:errorBlock];
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
     
     onResult:^(NSDictionary *map) {
         if ([[map objectForKey:BUCJsonResultKey] isEqualToString:BUCJsonResultFail]) {
             if ([[map objectForKey:BUCJsonMessageKey] isEqualToString:BUCJsonNoPermission]) {
                 errorBlock([self noPermissionError]);
                 return;
             }
             
             [authManager
              updateSessionOnSuccess:^(void) {
                  [weakSelf loadJsonFromUrl:url json:json onSuccess:mapBlock onError:errorBlock];
              }
              
              onFail:^(NSError *error) {
                  errorBlock(error);
              }];
             
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
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    NSArray *rawArray = [map objectForKey:listKey];
    
    for (NSDictionary *rawMap in rawArray) {
        BUCPost *post = [[BUCPost alloc] init];
        
        post.pid = [rawMap objectForKey:BUCJsonPidKey];
        post.tid = [rawMap objectForKey:BUCJsonTidKey];
        post.fid = [rawMap objectForKey:BUCJsonFidKey];
        
        post.fname = [self urldecode:[rawMap objectForKey:BUCJsonForumNameKey]];
        
        post.user = [self urldecode:[rawMap objectForKey:BUCJsonUsernameKey]];
        post.uid = [rawMap objectForKey:BUCJsonUidKey];
        
        post.avatar = [self.htmlScraper avatarUrlFromHtml:[self urldecode:[rawMap objectForKey:BUCJsonAvatarKey]]];
        

        if ([listKey isEqualToString:BUCJsonNewListKey]) {
            post.title = [self.htmlScraper richTextFromHtml:[self urldecode:[rawMap objectForKey:BUCJsonPostNameKey]]];
            NSString *lastPostDateline = [self parseDateline:[self urldecode:[[rawMap objectForKey:BUCJsonLastReplyKey] objectForKey:BUCJsonLastReplyDateKey]]];
            post.lastPoster = [self urldecode:[[rawMap objectForKey:BUCJsonLastReplyKey] objectForKey:BUCJsonLastReplyUserKey]];
            post.lastPostDateline = [NSString stringWithFormat:@"最后回复: %@ by", lastPostDateline];
            post.statistic = [NSString stringWithFormat:@"• %@回复", [rawMap objectForKey:BUCJsonPostChildCountKey]];
        } else if ([listKey isEqualToString:BUCJsonDetailListKey]) {
            NSMutableString *content = [[NSMutableString alloc] init];
            NSString *title = [self urldecode:[rawMap objectForKey:BUCJsonPostTitleKey]];
            if (title) {
                title = [NSString stringWithFormat:BUCPostTitleTemplate, title];
                [content appendString:title];
            }
            
            NSString *body = [self urldecode:[rawMap objectForKey:BUCJsonPostContentKey]];
            if (body) {
                [content appendString:body];
            }
            
            NSString *attachment = [self urldecode:[rawMap objectForKey:BUCJsonAttachmentKey]];
            if (attachment) {
                NSString *filetype = [self urldecode:[rawMap objectForKey:BUCJsonAttachmentTypeKey]];
                if (filetype && [filetype rangeOfString:BUCImageFileTypePrefix].length > 0) {
                    attachment = [NSString stringWithFormat:BUCPostAttachmentTemplate, attachment];
                    [content appendString:attachment];
                }
            }
            
            post.content = [self.htmlScraper richTextFromHtml:content];
        } else {
            post.title = [self.htmlScraper richTextFromHtml:[self urldecode:[rawMap objectForKey:BUCJsonPostTitleKey]]];
            NSString *viewCount = [rawMap objectForKey:BUCJsonViewCountKey];
            NSString *childCount = [rawMap objectForKey:BUCJsonChildCountKey];
            post.statistic = [NSString stringWithFormat:@"• %@回复/%@查看", childCount, viewCount];
            NSString *lastPostDateline = [self parseDateline:[rawMap objectForKey:BUCJsonLastPostDateKey]];
            post.lastPostDateline = [NSString stringWithFormat:@"最后回复: %@ by", lastPostDateline];
            post.lastPoster = [self urldecode:[rawMap objectForKey:BUCJsonLastPostUserKey]];
        }
        
        post.dateline = [self parseDateline:[rawMap objectForKey:BUCJsonDateKey]];
        
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


- (UIImage *)imageFromData:(NSData *)data size:(CGSize)size url:(NSURL *)url {
    UIImage *image;
    
    if ([[url pathExtension] isEqualToString:@"gif"]) {
        image = [UIImage animatedImageWithAnimatedGIFData:data];
    } else {
        image = [UIImage imageWithData:data];
    }
    
    NSString *string;
    NSRegularExpression *pattern = [NSRegularExpression
                                    regularExpressionWithPattern:@"龜"
                                    options:NSRegularExpressionCaseInsensitive error:NULL];
    NSMutableArray *lineList = [[NSMutableArray alloc] init];
    [string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        NSTextCheckingResult *match = [pattern firstMatchInString:line
                                                          options:0
                                                            range:NSMakeRange(0, line.length)];
        if (match.numberOfRanges > 0) {
            [lineList addObject:line];
        }
    }];
    
    return image;
}


@end



















