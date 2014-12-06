#import "BUCNetworkEngine.h"


@interface BUCNetworkEngine ()


@property (nonatomic) NSURLSession *defaultSession;


@end


@implementation BUCNetworkEngine
#pragma mark - init
- (instancetype)init {
    self = [super init];
    
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSString *cachePath = @"/MyCacheDirectory";

        NSURLCache *myCache = [[NSURLCache alloc] initWithMemoryCapacity: 16384 diskCapacity: 268435456 diskPath: cachePath];
        config.URLCache = myCache;
        config.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        config.timeoutIntervalForResource = 30;
        _defaultSession = [NSURLSession sessionWithConfiguration: config delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    }
    
    return self;
}


#pragma mark - public methods
- (void)fetchJsonFromUrl:(NSString *)url
                    json:(NSDictionary *)json
                onResult:(BUCMapBlock)mapBlock
                 onError:(BUCErrorBlock)errorBlock {
    
    NSError *error;
    NSURLRequest *request = [self requestFromURL:url json:json error:&error];
    if (!request) {
        errorBlock(error);
        return;
    }
    
    BUCNetworkEngine * __weak weakSelf = self;
    
    void (^block)(NSData *, NSURLResponse *, NSError *);
    block = ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *result;
        if (error || ((NSHTTPURLResponse *)response).statusCode != 200) {
            goto fail;
        }
        
        result = [NSJSONSerialization JSONObjectWithData:data
                                                     options:NSJSONReadingMutableContainers
                                                       error:&error];
        if (!result) {
            goto fail;
        }
        
        mapBlock(result);
        
        return;
        
    fail:
        errorBlock([weakSelf checkErr:error response:response]);
    };
    
    [[self.defaultSession dataTaskWithRequest:request completionHandler:block] resume];
}


- (void)fetchDataFromUrl:(NSURLRequest *)request onResult:(BUCDataBlock)dataBlock onError:(BUCErrorBlock)errorBlock {
    void(^urlSessionBlock)(NSData *, NSURLResponse *, NSError *);
    urlSessionBlock = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) {
            return;
        } else {
            dataBlock(data);
        }
    };
    
    [[self.defaultSession dataTaskWithRequest:request completionHandler:urlSessionBlock] resume];
}


#pragma mark - private methods
- (NSURLRequest *)requestFromURL:(NSString *)url json:(NSDictionary *)json error:(NSError **)error {
    static NSString * baseURL = @"http://out.bitunion.org/open_api/bu_%@.php";
//    baseURL = @"http://0.0.0.0/open_api/bu_%@.php";
    static NSString * const HTTPMethod = @"POST";
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:baseURL, url]]];
    NSMutableDictionary *dataJSON = [[NSMutableDictionary alloc] init];
    NSData *data;
    
    for (NSString *key in json) {
        [dataJSON setObject:[self urlencode:[json objectForKey:key]] forKey:key];
    }
    
    data = [NSJSONSerialization dataWithJSONObject:dataJSON options:0 error:error];
    if (!data) {
        return nil;
    }
    
    req.HTTPMethod = HTTPMethod;
    req.HTTPBody = data;
    
    return req;
}


- (NSString *)urlencode:(NSString *)string {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[string UTF8String];
    unsigned long sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ') {
            [output appendString:@"+"];
        }
        else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            
            [output appendFormat:@"%c", thisChar];
        }
        else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}


- (NSError *)checkErr:(NSError *)error response:(NSURLResponse *)response {
    static NSString * const BUCServerERROR =     @"服务器错误，请稍候再试";
    static NSString * const BUC404ERROR = @"服务器404错误，请稍候再试";
    static NSString * const BUCTimeoutERROR =    @"服务器连接超时";
    static NSString * const BUCConnenctionERROR =    @"无法连接至服务器";
    static NSString * const BUCInternetERROR = @"无网络连接，请检查网络连接";
    static NSString * const BUCUnknownERROR =    @"未知错误";
    static NSString * const BUCHTTPErrorDomain = @"buc.http.errorDomain";
    
    NSDictionary *errorInfo;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 500) {
            errorInfo = @{NSLocalizedDescriptionKey:BUCServerERROR};
        } else if (httpResponse.statusCode == 404) {
            errorInfo = @{NSLocalizedDescriptionKey:BUC404ERROR};
        } else {
            errorInfo = @{NSLocalizedDescriptionKey:BUCUnknownERROR};
        }
        
        return [NSError errorWithDomain:BUCHTTPErrorDomain code:0 userInfo:errorInfo];

    } else if (error.code == NSURLErrorTimedOut) {
        errorInfo = @{NSLocalizedDescriptionKey:BUCTimeoutERROR};
    } else if (error.code == NSURLErrorCannotConnectToHost) {
        errorInfo = @{NSLocalizedDescriptionKey:BUCConnenctionERROR};
    } else if(error.code == NSURLErrorNotConnectedToInternet) {
        errorInfo = @{NSLocalizedDescriptionKey:BUCInternetERROR};
    } else {
        errorInfo = @{NSLocalizedDescriptionKey:BUCUnknownERROR};
    }
        
    return [NSError errorWithDomain:error.domain code:error.code userInfo:errorInfo];
}


@end















