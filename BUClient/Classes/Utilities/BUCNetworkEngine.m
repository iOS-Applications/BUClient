//
//  BUCNetworkEngine.m
//  BUClient
//
//  Created by Joe Jeong on 1/25/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCNetworkEngine.h"

@interface BUCNetworkEngine ()

@property (nonatomic) NSURLSession *defaultSession;
@property (nonatomic) NSURLSessionConfiguration *defaultConfigObject;
@property (nonatomic) NSURLSessionDataTask *currentTask;

@property (readwrite, nonatomic) NSString *baseUrl;
@end

@implementation BUCNetworkEngine
#pragma mark - singleton class method
+(BUCNetworkEngine *)sharedInstance
{
    static BUCNetworkEngine *sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark - init
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSString *cachePath = @"/MyCacheDirectory";

        NSURLCache *myCache = [[NSURLCache alloc] initWithMemoryCapacity: 16384 diskCapacity: 268435456 diskPath: cachePath];
        _defaultConfigObject.URLCache = myCache;
        _defaultConfigObject.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        _defaultConfigObject.timeoutIntervalForResource = 30;
        _defaultSession = [NSURLSession sessionWithConfiguration: _defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
        
        _baseUrl = @"http://out.bitunion.org/open_api/bu_%@.php";
    }
    
    return self;
}

#pragma mark - public methods
- (void)processRequest:(NSMutableURLRequest *)request
                  json:(NSDictionary *)json
              onResult:(networkResultBlock)resultBlock
               onError:(networkErrorBlock)errorBlock
{
    NSError *error = nil;
    request = [self setUpRequest:request json:json error:&error];
    if (!request)
    {
        if (errorBlock)
        {
            errorBlock(error);
        }
        
        return;
    }
    
    BUCNetworkEngine * __weak weakSelf = self;
    
    void (^urlSessionBlock)(NSData *, NSURLResponse *, NSError *);
    urlSessionBlock = ^(NSData *data, NSURLResponse *response, NSError *error)
    {
        NSDictionary *resultJSON = nil;
        if (error)
        {
            goto fail;
        }
        
        resultJSON = [NSJSONSerialization JSONObjectWithData:data
                                                     options:NSJSONReadingMutableContainers
                                                       error:&error];
        if (!resultJSON)
        {
            goto fail;
        }
        
        if (resultBlock)
        {
            resultBlock(resultJSON);
        }
        
        return;
        
    fail:
        if (errorBlock)
        {
            errorBlock([weakSelf checkErr:error response:response]);
        }
    };
    
    NSURLSessionDataTask *task = [self.defaultSession dataTaskWithRequest:request completionHandler:urlSessionBlock];
    
    [task resume];
}

#pragma mark - private methods
- (NSMutableURLRequest *)setUpRequest:(NSMutableURLRequest *)req json:(NSDictionary *)json error:(NSError **)error
{
    NSMutableDictionary *dataJson = [[NSMutableDictionary alloc] init];
    for (NSString *key in json)
    {
        [dataJson setObject:[self urlencode:[json objectForKey:key]] forKey:key];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:dataJson options:0 error:error];
    if (!data)
    {
        return nil;
    }
    
    req.HTTPBody = data;
    
    return req;
}

- (NSString *)urlencode:(NSString *)string
{
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[string UTF8String];
    unsigned long sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i)
    {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ')
        {
            [output appendString:@"+"];
        }
        else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9'))
        {
            [output appendFormat:@"%c", thisChar];
        }
        else
        {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

- (NSError *)checkErr:(NSError *)error response:(NSURLResponse *)response
{
    static NSString *serverErrMsg =     @"服务器错误，请稍后再试";
    static NSString *timeoutErrMsg =    @"服务器连接超时";
    static NSString *cancelErrMsg =     @"";
    static NSString *connectErrMsg =    @"无法连接至服务器";
    static NSString *noInternetErrMsg = @"无网络连接，请检查网络连接";
    static NSString *unknownErrMsg =    @"未知错误";
    
    static NSString *bucHttpErrorDomain = @"org.bitunion.buc.HttpErrorDomain";
    static NSString *bucNetworkErrorDomain = @"org.bitunion.buc.NetworkErrorDomain";
    
    static NSError *serverError = nil;
    static NSError *timeoutError = nil;
    static NSError *cancelError = nil;
    static NSError *connectError = nil;
    static NSError *noInternetError = nil;
    static NSError *unknownError = nil;
    
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate, ^{
        serverError =  [NSError errorWithDomain:bucHttpErrorDomain code:500 userInfo:@{NSLocalizedDescriptionKey: serverErrMsg}];
        timeoutError = [NSError errorWithDomain:bucNetworkErrorDomain code:NSURLErrorTimedOut userInfo:@{NSLocalizedDescriptionKey:timeoutErrMsg}];
        cancelError =  [NSError errorWithDomain:bucNetworkErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:cancelErrMsg}];
        connectError = [NSError errorWithDomain:bucNetworkErrorDomain code:NSURLErrorCannotConnectToHost userInfo:@{NSLocalizedDescriptionKey:connectErrMsg}];
        noInternetError = [NSError errorWithDomain:bucNetworkErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey:noInternetErrMsg}];
        unknownError = [NSError errorWithDomain:bucNetworkErrorDomain code:NSURLErrorUnknown userInfo:@{NSLocalizedDescriptionKey:unknownErrMsg}];
    });
    
    NSError *resultError = nil;
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if (httpResponse.statusCode == 500)
        {
            resultError = serverError;
        }
    }
    else if (error.code == NSURLErrorTimedOut)
    {
        resultError = timeoutError;
    }
    else if (error.code == NSURLErrorCancelled)
    {
        resultError = cancelError;
    }
    else if (error.code == NSURLErrorCannotConnectToHost)
    {
        resultError = connectError;
    }
    else if(error.code == NSURLErrorNotConnectedToInternet)
    {
        resultError = noInternetError;
    }
    else
    {
        resultError = unknownError;
    }
    
    return resultError;
}
@end















