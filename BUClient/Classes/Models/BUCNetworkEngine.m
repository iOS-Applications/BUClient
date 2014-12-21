#import "BUCNetworkEngine.h"


@interface BUCNetworkEngine ()


@property (nonatomic) NSURLSession *defaultSession;
@property (nonatomic) NSString *host;


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
        
        _host = [[NSUserDefaults standardUserDefaults] stringForKey:@"host"];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hostChanged) name:BUCHostChangedNotification object:nil];
    }
    
    return self;
}


- (void)hostChanged {
    self.host = [[NSUserDefaults standardUserDefaults] stringForKey:@"host"];
}


#pragma mark - public methods
- (void)fetchJsonFromUrl:(NSString *)url
                    json:(NSDictionary *)json
              attachment:(UIImage *)attachment
                  isForm:(BOOL)isForm
                onResult:(BUCMapBlock)mapBlock
                 onError:(BUCStringBlock)errorBlock {
    
    NSError *error;
    NSURLRequest *request = [self requestWithUrl:url json:json attachment:attachment isForm:isForm error:&error];
    if (!request) {
        errorBlock(@"未知错误");
        return;
    }
    
    void (^block)(NSData *, NSURLResponse *, NSError *);
    block = ^(NSData *data, NSURLResponse *response, NSError *error) {
        [self callbackWithData:data response:response error:error mapBlock:mapBlock errorBlock:errorBlock];
    };
    
    [[self.defaultSession dataTaskWithRequest:request completionHandler:block] resume];
}


- (void)fetchDataFromUrl:(NSURLRequest *)request onResult:(BUCDataBlock)dataBlock onError:(BUCStringBlock)errorBlock {
    void(^urlSessionBlock)(NSData *, NSURLResponse *, NSError *);
    urlSessionBlock = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data) {
            dataBlock(data);
        }
    };
    
    [[self.defaultSession dataTaskWithRequest:request completionHandler:urlSessionBlock] resume];
}


- (void)callbackWithData:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error mapBlock:(BUCMapBlock)mapBlock errorBlock:(BUCStringBlock)errorBlock {
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
    errorBlock([self checkErr:error response:response]);
}


#pragma mark - private methods
- (NSURLRequest *)requestWithUrl:(NSString *)url json:(NSDictionary *)json attachment:(UIImage *)attachment isForm:(BOOL)isForm error:(NSError **)error {
    NSString *baseURL = [NSString stringWithFormat:@"%@/open_api/bu_%%@.php", self.host];
//    baseURL = @"http://192.168.1.100/open_api/bu_%@.php";
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
    
    static NSString * const boundary = @"0Xbooooooooooooooooundary0Xyeah!";
    if (isForm) {
        [req setValue:[NSString stringWithFormat:@"multipart/form-data;boundary=%@",boundary] forHTTPHeaderField:@"Content-type"];
        data = [self formDataWithData:data attachment:attachment boundary:boundary];
    }
    
    req.HTTPMethod = @"POST";
    req.HTTPBody = data;
    
    return req;
}


- (NSData *)formDataWithData:(NSData *)data attachment:(UIImage *)attachment boundary:(NSString *)boundary {
    NSMutableData * body=[NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"json\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary]dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (attachment) {
        [body appendData:[@"Content-Disposition: form-data;name=\"attach\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/png\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:UIImagePNGRepresentation(attachment)];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary]dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return body;
}


- (NSString *)urlencode:(NSString *)string {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[string UTF8String];
    unsigned long sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ') {
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    
    return output;
}


- (NSString *)checkErr:(NSError *)error response:(NSURLResponse *)response {
    NSString *errorMsg;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 500) {
            errorMsg = @"服务器错误，请稍候再试";
        } else if (httpResponse.statusCode == 404) {
            errorMsg = @"服务器404错误，请稍候再试";
        } else {
            errorMsg = @"未知错误";
        }
    } else if (error.code == NSURLErrorTimedOut) {
        errorMsg = @"服务器连接超时";
    } else if (error.code == NSURLErrorCannotConnectToHost) {
        errorMsg = @"无法连接至服务器";
    } else if (error.code == NSURLErrorNotConnectedToInternet) {
        errorMsg = @"无网络连接，请检查网络连接";
    } else if (error.code == NSURLErrorCannotFindHost) {
        errorMsg = @"域名解析失败，请检查网络";
    } else {
        errorMsg = @"未知错误";
    }
    
    return errorMsg;
}


@end















