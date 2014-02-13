//
//  BUCNetworkEngine.m
//  BUClient
//
//  Created by Joe Jeong on 1/25/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCNetworkEngine.h"
#import "NSString+NSString_Extended.h"
#import "Reachability.h"
#import "BUCAvatar.h"

@interface BUCNetworkEngine ()
{
    Reachability *lanHostReach;
    Reachability *wanHostReach;
}

@property NSURLSession *defaultSession;
@property NSURLSessionConfiguration *defaultConfigObject;
@property NSURLSessionDataTask *currentTask;

@property NSString *baseUrl;
@end

@implementation BUCNetworkEngine
#pragma mark - singleton class method
+(BUCNetworkEngine *)sharedInstance
{
    static BUCNetworkEngine *sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
                      sharedInstance = [[self alloc] init];
                  });
    
    return sharedInstance;
}

#pragma mark - init
- (id)init
{
    self = [super init];
    
    if (self) {
        _defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSString *cachePath = @"/MyCacheDirectory";

        NSURLCache *myCache = [[NSURLCache alloc] initWithMemoryCapacity: 16384 diskCapacity: 268435456 diskPath: cachePath];
        _defaultConfigObject.URLCache = myCache;
        _defaultConfigObject.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        _defaultConfigObject.timeoutIntervalForResource = 30;
        _defaultSession = [NSURLSession sessionWithConfiguration: _defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
        _responseDic = nil;
        _hostIsOn = NO;
        
        _responseDataArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < 20; i++) {
            BUCAvatar *avatar = [[BUCAvatar alloc] init];
            [_responseDataArray addObject:avatar];
        }
        
        // test code begin
        _baseUrl = @"http://0.0.0.0:8080/open_api/bu_%@.php";
        _hostIsOn = YES;
        // test code end
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkStatusChange:) name:kReachabilityChangedNotification object:nil];
        
        lanHostReach = [Reachability reachabilityWithHostName:@"www.bitunion.org"];
        [lanHostReach startNotifier];
        
        wanHostReach = [Reachability reachabilityWithHostName:@"out.bitunion.org"];
        [wanHostReach startNotifier];
    }
    
    return self;
}

#pragma mark - notification handler methods
- (void)handleNetworkStatusChange:(NSNotification *)notice
{
    [self checkNetworkStatus];
}

#pragma mark - public methods
- (NSString *)processSyncRequest:(NSDictionary *)requestDic
{
    self.responseDic = nil;
    
    NSURLRequest *request = [self requestFromDic:requestDic];
    if (!request) return @"数据解析错误，请重新尝试";
    
    NSError *error = nil;
    NSURLResponse *response;
    NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *errorMessage = nil;
    
    errorMessage = [self checkError:error response:response data:receivedData];
    
    return errorMessage;
}

- (void)processAsyncRequest:(NSDictionary *)requestDic completionHandler:(void (^)(NSString *message))completionHandler
{
    self.responseDic = nil;
    
    NSURLRequest *request = [self requestFromDic:requestDic];
    if (!request) {
        completionHandler(@"数据解析错误，请重新尝试");
        return;
    }
    
    BUCNetworkEngine * __weak weakEngine = self;
    self.currentTask = [self.defaultSession dataTaskWithRequest:request
                                              completionHandler:
                        ^(NSData *data, NSURLResponse *response, NSError *error) {
                            NSString *errorMessage = [weakEngine checkError:error response:response data:data];
                            completionHandler(errorMessage);
                        }];
    
    [self.currentTask resume];
}

- (void)processAsyncQueueRequest:(NSURLRequest *)request index:(NSInteger)index
{
    BUCAvatar *avatar = [self.responseDataArray objectAtIndex:index];
    avatar.loadEnded = NO;
    
    NSURLSessionDataTask *task = [self.defaultSession dataTaskWithRequest:request
                                              completionHandler:
                        ^(NSData *data, NSURLResponse *response, NSError *error) {
                            if (error) {
                                avatar.error = error;
                                goto done;
                            }
                            
                            if ([data length]) {
                                avatar.data = data;
                            } else {
                                avatar.error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
                            }
                            
                        done:
                            avatar.loadEnded = YES;
                        }];
    [task resume];
}

- (void)cancelCurrentTask
{
    [self.currentTask cancel];
}

- (void)suspendCurrentTask
{
    [self.currentTask suspend];
}

- (void)resumeCurrentTask
{
    [self.currentTask resume];
}

- (BOOL)checkNetworkStatus
{
    // test code start
    return YES;
    // test code end
    
    NSData *data = nil;
    NSError *err = nil;
    NSURLResponse *response = nil;
    NSURL *url = [NSURL URLWithString:@"http://www.bitunion.org/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:2];
    
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    
    if (!err) {
        self.baseUrl = @"http://www.bitunion.org/open_api/bu_%@.php";
        self.hostIsOn = YES;
        return YES;
    }
    
    err = nil;
    url = [NSURL URLWithString:@"http://out.bitunion.org/"];
    request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:2];
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    if (!err) {
        self.baseUrl = @"http://out.bitunion.org/open_api/bu_%@.php";
        self.hostIsOn = YES;
        return YES;
    }
    
    return NO;
}

#pragma mark - private methods
- (NSString *)checkError:(NSError *)error response:(NSURLResponse *)response data:(NSData *)data
{
    NSString *errorMessage = nil;
    
    if (error) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
            if (httpResponse.statusCode == 500) errorMessage = @"服务器错误，请稍后再试";
        } else if (error.code == NSURLErrorTimedOut) {
            errorMessage = @"服务器连接超时，请检查网络连接或稍后再试";
        } else if (error.code == NSURLErrorCancelled) {
            errorMessage = @"";
        } else if (error.code == NSURLErrorCannotConnectToHost) {
            errorMessage = @"无法连接至服务器，请检查网络连接或稍后再试";
        }else {
            errorMessage = @"未知错误";
        }
        
        return errorMessage;
    }
    
    if ([data length] > 0) {
        self.responseDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (!self.responseDic) errorMessage = @"数据解析错误，请重新尝试";
    } else {
        errorMessage = @"无法加载数据，请重新尝试";
    }
    
    return errorMessage;
}

- (NSURLRequest *)requestFromDic:(NSDictionary *)requestDic
{
    NSMutableDictionary *postDic = [[NSMutableDictionary alloc] init];
    NSDictionary *dataDic = [requestDic objectForKey:@"dataDic"];
    for (NSString *key in dataDic) {
        [postDic setValue:[[dataDic objectForKey:key] urlencode] forKey:key];
    }
    
    NSError *err = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:postDic options:0 error:&err];
    if (!postData) return nil;
    
    NSMutableURLRequest *request;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:self.baseUrl, [requestDic objectForKey:@"url"]]];
    
    NSString *method = [requestDic objectForKey:@"method"];
    request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    [request setHTTPBody:postData];
    
    return request;
}

@end

















