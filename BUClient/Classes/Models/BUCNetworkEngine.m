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
    }
    
    return self;
}

#pragma mark - public methods
- (void)fetchDataFromURL:(NSString *)url
                    json:(NSDictionary *)json
                onResult:(networkResultBlock)resultBlock
                 onError:(networkErrorBlock)errorBlock
{
    NSError *error = nil;
    NSURLRequest *request = [self requestFromURL:url json:json error:&error];
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
        if (error || ((NSHTTPURLResponse *)response).statusCode != 200)
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
    
    [[self.defaultSession dataTaskWithRequest:request completionHandler:urlSessionBlock] resume];
}

#pragma mark - private methods
- (NSURLRequest *)requestFromURL:(NSString *)url json:(NSDictionary *)json error:(NSError **)error
{
    NSString *baseURL = @"http://out.bitunion.org/open_api/bu_%@.php";
    baseURL = @"http://0.0.0.0/open_api/bu_%@.php";
    NSString *HTTPMethod = @"POST";
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:baseURL, url]]];
    NSMutableDictionary *dataJSON = [[NSMutableDictionary alloc] init];
    NSData *data = nil;
    
    for (NSString *key in json)
    {
        [dataJSON setObject:[self urlencode:[json objectForKey:key]] forKey:key];
    }
    
    data = [NSJSONSerialization dataWithJSONObject:dataJSON options:0 error:error];
    if (!data)
    {
        return nil;
    }
    
    req.HTTPMethod = HTTPMethod;
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
    NSString *serverERROR =     @"服务器错误，请稍候再试";
    NSString *notFoundERROR = @"服务器404错误，请稍候再试";
    NSString *timeoutERROR =    @"服务器连接超时";
    NSString *connenctionERROR =    @"无法连接至服务器";
    NSString *noInternetERROR = @"无网络连接，请检查网络连接";
    NSString *unknownERROR =    @"未知错误";
    
    NSDictionary *errorInfo = nil;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if (httpResponse.statusCode == 500)
        {
            errorInfo = @{NSLocalizedDescriptionKey:serverERROR};
        }
        else if (httpResponse.statusCode == 404)
        {
            errorInfo = @{NSLocalizedDescriptionKey:notFoundERROR};
        }
        else
        {
            errorInfo = @{NSLocalizedDescriptionKey:unknownERROR};
        }
        
        return [NSError errorWithDomain:@"buc.http.errorDomain" code:0 userInfo:errorInfo];

    }
    else if (error.code == NSURLErrorTimedOut)
    {
        errorInfo = @{NSLocalizedDescriptionKey:timeoutERROR};
    }
    else if (error.code == NSURLErrorCannotConnectToHost)
    {
        errorInfo = @{NSLocalizedDescriptionKey:connenctionERROR};
    }
    else if(error.code == NSURLErrorNotConnectedToInternet)
    {
        errorInfo = @{NSLocalizedDescriptionKey:noInternetERROR};
    }
    else
    {
        errorInfo = @{NSLocalizedDescriptionKey:unknownERROR};
    }
        
    return [NSError errorWithDomain:error.domain code:error.code userInfo:errorInfo];
}
@end















