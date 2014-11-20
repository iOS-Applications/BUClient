#import "BUCDataManager.h"
#import "BUCNetworkEngine.h"
#import "BUCAuthManager.h"
#import "BUCHTMLScraper.h"
#import "UIImage+animatedGIF.h"
#import "UIImage+SimpleResize.h"
#import "BUCModels.h"


static NSString * const BUCNewListKey = @"newlist";
static NSString * const BUCDetailListKey = @"postlist";
static NSString * const BUCForumListKey = @"threadlist";


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
    [json setObject:[BUCAuthManager sharedInstance].currentUser forKey:@"username"];
    
    [self loadListFromUrl:@"home" json:json listKey:BUCNewListKey onSuccess:arrayBlock onError:errorBlock];
}


- (void)getForumList:(NSString *)fid from:(NSString *)from to:(NSString *)to OnSuccess:(ArrayBlock)arrayBlock onError:(ErrorBlock)errorBlock {
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:@"thread" forKey:@"action"];
    [json setObject:[BUCAuthManager sharedInstance].currentUser forKey:@"username"];
    [json setObject:fid forKey:@"fid"];
    [json setObject:from forKey:@"from"];
    [json setObject:to forKey:@"to"];
    
    [self loadListFromUrl:@"thread" json:json listKey:BUCForumListKey onSuccess:arrayBlock onError:errorBlock];
}


- (void)getPost:(NSString *)postID from:(NSString *)from to:(NSString *)to onSuccess:(ArrayBlock)arrayBlock onError:(ErrorBlock)errorBlock {
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:@"post" forKey:@"action"];
    [json setObject:[BUCAuthManager sharedInstance].currentUser forKey:@"username"];
    [json setObject:postID forKey:@"tid"];
    [json setObject:from forKey:@"from"];
    [json setObject:to forKey:@"to"];
    
    [self loadListFromUrl:@"post" json:json listKey:BUCDetailListKey onSuccess:arrayBlock onError:errorBlock];
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


- (UIImage *)imageFromData:(NSData *)data url:(NSURL *)url {
    UIImage *image;
    
    if ([[url pathExtension] isEqualToString:@"gif"]) {
        image = [UIImage animatedImageWithAnimatedGIFData:data];
    } else {
        image = [UIImage imageWithData:data];
    }
    
    return image;
}


#pragma mark - networking
- (void)loadListFromUrl:(NSString *)url
                   json:(NSMutableDictionary *)json
                listKey:(NSString *)listKey
              onSuccess:(ArrayBlock)arrayBlock
                onError:(ErrorBlock)errorBlock {
    
    BUCDataManager * __weak weakSelf = self;
    BUCAuthManager *authManager = [BUCAuthManager sharedInstance];
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    
    if (!authManager.session) {
        [authManager
         updateSessionOnSuccess:^(void) {
             [weakSelf loadListFromUrl:url json:json listKey:listKey onSuccess:arrayBlock onError:errorBlock];
         }
         
         onFail:^(NSError *error) {
             errorBlock(error);
         }];
        
        return;
    }
    
    
    SuccessBlock successBlock = ^(NSDictionary *json) {
        NSMutableArray *list = [[NSMutableArray alloc] init];
        NSArray *rawArray = [json objectForKey:listKey];
        
        NSDictionary *metaAttribute = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]};
        
        for (NSDictionary *rawDic in rawArray) {
            BUCPost *post = [[BUCPost alloc] init];
            
            post.pid = [rawDic objectForKey:@"tid"];
            post.fid = [rawDic objectForKey:@"fid"];
            
            NSString *fname = [weakSelf urldecode:[rawDic objectForKey:@"fname"]];
            if (fname) {
                post.fname = [[NSAttributedString alloc] initWithString:fname attributes:metaAttribute];
            }
            
            post.user = [[NSAttributedString alloc] initWithString:[weakSelf urldecode:[rawDic objectForKey:@"author"]]
                                                        attributes:metaAttribute];
            post.uid = [rawDic objectForKey:@"authorid"];
            
            post.avatar = [weakSelf.htmlScraper avatarUrlFromHtml:[weakSelf urldecode:[rawDic objectForKey:@"avatar"]]];
            
            if ([listKey isEqualToString:BUCNewListKey]) {
                post.title = [weakSelf.htmlScraper richTextFromHtml:[weakSelf urldecode:[rawDic objectForKey:@"pname"]]];
                NSString *lastPostDateline = [weakSelf parseDateline:[weakSelf urldecode:[[rawDic objectForKey:@"lastreply"] objectForKey:@"when"]]];
                NSString *lastPoster = [weakSelf urldecode:[[rawDic objectForKey:@"lastreply"] objectForKey:@"who"]];
                post.lastPoster = [[NSAttributedString alloc] initWithString:lastPoster attributes:metaAttribute];
                post.lastPostDateline = [[NSAttributedString alloc] initWithString:lastPostDateline attributes:metaAttribute];
                post.childCount = [rawDic objectForKey:@"tid_sum"];
            } else if ([listKey isEqualToString:BUCDetailListKey]) {
                NSMutableString *content = [[NSMutableString alloc] init];
                NSString *title = [weakSelf urldecode:[rawDic objectForKey:@"subject"]];
                if (title) {
                    title = [NSString stringWithFormat:@"<b>%@</b>\n\n", title];
                    [content appendString:title];
                }
                
                NSString *body = [weakSelf urldecode:[rawDic objectForKey:@"message"]];
                if (body) {
                    [content appendString:body];
                }
                
                NSString *attachment = [weakSelf urldecode:[rawDic objectForKey:@"attachment"]];
                if (attachment) {
                    NSString *filetype = [weakSelf urldecode:[rawDic objectForKey:@"filetype"]];
                    if (filetype && [filetype rangeOfString:@"image/"].length > 0) {
                        attachment = [NSString stringWithFormat:@"\n\n本帖包含图片附件:\n\n<img src='http://out.bitunion.org/%@'>", attachment];
                        [content appendString:attachment];
                    }
                }
                
                post.content = [weakSelf.htmlScraper richTextFromHtml:content];
            } else {
                post.title = [weakSelf.htmlScraper richTextFromHtml:[weakSelf urldecode:[rawDic objectForKey:@"subject"]]];
                post.viewCount = [rawDic objectForKey:@"views"];
                post.childCount = [rawDic objectForKey:@"replies"];
                NSString *lastPostDateline = [weakSelf parseDateline:[rawDic objectForKey:@"lastpost"]];
                NSString *lastPoster = [weakSelf urldecode:[rawDic objectForKey:@"lastposter"]];
                post.lastPostDateline = [[NSAttributedString alloc] initWithString:lastPostDateline attributes:metaAttribute];
                post.lastPoster = [[NSAttributedString alloc] initWithString:lastPoster attributes:metaAttribute];
            }
            
            NSString *dateline = [weakSelf parseDateline:[rawDic objectForKey:@"dateline"]];
            if (dateline) {
                post.dateline = [[NSAttributedString alloc] initWithString:dateline attributes:metaAttribute];
            }
            
            [list addObject:post];
        }
        
        arrayBlock(list);
    };
    
    
    [json setObject:authManager.session forKey:@"session"];
    
    [engine
     fetchDataFromUrl:url
     
     json:json
     
     onResult: ^(NSDictionary *resultJSON) {
         if ([[resultJSON objectForKey:@"result"] isEqualToString:@"fail"]) {
             if ([[resultJSON objectForKey:@"msg"] isEqualToString:@"thread_nopermission"]) {
                 errorBlock([self returnFailError]);
                 return;
             }
             
             [authManager
              updateSessionOnSuccess:^(void) {
                  [weakSelf loadListFromUrl:url json:json listKey:listKey onSuccess:arrayBlock onError:errorBlock];
              }
              
              onFail:^(NSError *error) {
                  errorBlock(error);
              }];
         }
         
         successBlock(resultJSON);
     }
     
     onError:errorBlock];
}


#pragma mark - utilies
- (NSString *)urldecode:(NSString *)string {
    if (!string || (id)string == [NSNull null] || string.length == 0) {
        return nil;
    }
    
    return [[string stringByReplacingOccurrencesOfString:@"+" withString:@" "]
            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


- (NSError *)returnFailError {
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
        [dateFormatter setDateFormat:@"yyyy/MM/	dd"];
        output = [dateFormatter stringFromDate:date];
    }
    
    return output;
}


@end



















