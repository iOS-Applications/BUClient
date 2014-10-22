//
//  BUCNetworkEngine.m
//  BUClient
//
//  Created by Joe Jeong on 1/25/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCNetworkEngine.h"
#import "NSObject+BUCTools.h"

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
- (NSURLSessionDataTask *)processRequest:(NSURLRequest *)request
                                onResult:(networkResultBlock)resultBlock
                                 onError:(networkErrorBlock)errorBlock
{
    BUCNetworkEngine * __weak weakSelf = self;
    
    void (^urlSessionBlock)(NSData *, NSURLResponse *, NSError *);
    urlSessionBlock = ^(NSData *data, NSURLResponse *response, NSError *error)
    {
        if (error)
        {
            errorBlock([weakSelf checkErr:error response:response]);
            return;
        }
        
        NSDictionary *resultJSON = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&error];
        if (!resultJSON)
        {
            errorBlock(error);
            return;
        }
        
        resultBlock(resultJSON);
    };
    
    NSURLSessionDataTask *task = [self.defaultSession dataTaskWithRequest:request completionHandler:urlSessionBlock];
    
    [task resume];
    
    return task;
}

#pragma mark - private methods
- (NSError *)checkErr:(NSError *)error response:(NSURLResponse *)response
{
    static NSString *serverErrMsg =     @"服务器错误，请稍后再试";
    static NSString *timeoutErrMsg =    @"服务器连接超时，请检查网络连接";
    static NSString *cancelErrMsg =     @"";
    static NSString *connectErrMsg =    @"无法连接至服务器，请检查网络连接";
    static NSString *unknownErrMsg =    @"未知错误";
    
    static NSString *bucHttpErrorDomain = @"org.bitunion.buc.HttpErrorDomain";
    static NSString *bucNetworkErrorDomain = @"org.bitunion.buc.NetworkErrorDomain";
    
    static NSError *serverError = nil;
    static NSError *timeoutError = nil;
    static NSError *cancelError = nil;
    static NSError *connectError = nil;
    static NSError *unknownError = nil;
    
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate, ^{
        serverError =  [NSError errorWithDomain:bucHttpErrorDomain code:500 userInfo:@{NSLocalizedDescriptionKey: serverErrMsg}];
        timeoutError = [NSError errorWithDomain:bucNetworkErrorDomain code:NSURLErrorTimedOut userInfo:@{NSLocalizedDescriptionKey:timeoutErrMsg}];
        cancelError =  [NSError errorWithDomain:bucNetworkErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:cancelErrMsg}];
        connectError = [NSError errorWithDomain:bucNetworkErrorDomain code:NSURLErrorCannotConnectToHost userInfo:@{NSLocalizedDescriptionKey:connectErrMsg}];
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
    else
    {
        resultError = unknownError;
    }
    
    return resultError;
}
@end















