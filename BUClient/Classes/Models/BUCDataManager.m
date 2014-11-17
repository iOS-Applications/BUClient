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
        NSDictionary *headlineAttribute = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]};
        
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
            } else if ([listKey isEqualToString:BUCDetailListKey]) {
                post.title = [[NSAttributedString alloc] initWithString:[weakSelf urldecode:[rawDic objectForKey:@"subject"]] attributes:headlineAttribute];
            } else {
                // thread list
            }

            post.content = [weakSelf.htmlScraper richTextFromHtml:[weakSelf urldecode:[rawDic objectForKey:@"message"]]];
            post.dateline = [rawDic objectForKey:@"dateline"];
            
            post.childCount = [rawDic objectForKey:@"tid_sum"];
            
            NSString *when = [weakSelf urldecode:[[rawDic objectForKey:@"lastreply"] objectForKey:@"when"]];
            NSString *who = [weakSelf urldecode:[[rawDic objectForKey:@"lastreply"] objectForKey:@"who"]];
            if (when && who) {
                post.lastReply = [[BUCPost alloc] init];
                post.lastReply.user = [[NSAttributedString alloc] initWithString:who attributes:metaAttribute];
                post.lastReply.dateline = when;
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
    if (!string) {
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


@end



















