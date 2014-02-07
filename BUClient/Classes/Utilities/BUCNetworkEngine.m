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
        
        NSArray *myPathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *myPath    = [myPathList  objectAtIndex:0];
        
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        
        NSString *fullCachePath = [[myPath stringByAppendingPathComponent:bundleIdentifier] stringByAppendingPathComponent:cachePath];
        NSLog(@"Cache path: %@\n", fullCachePath);
        NSURLCache *myCache = [[NSURLCache alloc] initWithMemoryCapacity: 16384 diskCapacity: 268435456 diskPath: cachePath];
        _defaultConfigObject.URLCache = myCache;
        _defaultConfigObject.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        _defaultConfigObject.timeoutIntervalForResource = 30;
        _defaultSession = [NSURLSession sessionWithConfiguration: _defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
        _responseDic = nil;
        _hostIsOn = NO;
        
        // test code begin
        _baseUrl = @"http://0.0.0.0:8080/open_api/bu_%@.php";
        _hostIsOn = YES;
        // test code end
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkStatusChange:) name:kReachabilityChangedNotification object:nil];
        
        lanHostReach = [Reachability reachabilityWithHostName:@"www.bitunion.org"];
        [lanHostReach startNotifier];
        
        // check if a pathway to a random host exists
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
- (void)processRequestDic:(NSDictionary *)requestDic sync:(BOOL)sync completionHandler:(void (^)(NSString *message))completionHandler
{
    self.responseDic = nil;
    NSMutableDictionary *postDic = [[NSMutableDictionary alloc] init];
    NSDictionary *dataDic = [requestDic objectForKey:@"dataDic"];
    for (NSString *key in dataDic) {
        [postDic setValue:[[dataDic objectForKey:key] urlencode] forKey:key];
    }
    
    NSError *err = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:postDic options:0 error:&err];
    if (!postData) {
        NSLog(@"Error parsing JSON: %@", err);
        return;
    }
    
    NSMutableURLRequest *request;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:self.baseUrl, [requestDic objectForKey:@"url"]]];

    NSString *method = [requestDic objectForKey:@"method"];
    request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    [request setHTTPBody:postData];

    if (sync) {
        [self processSyncRequest:request];
        return;
    }
    
    [self processAsyncRequest:request completionHandler:completionHandler];
}

- (void)cancelCurrentTask
{
    [self.currentTask cancel];
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
- (void)processSyncRequest:(NSURLRequest *)request;
{
    NSError *err = nil;
    NSURLResponse *response;
    NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    
    if (err) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
            NSLog(@"HTTP Error: %ld %@", (long)httpResponse.statusCode, err);
            goto failed;
        }
        NSLog(@"Error %@", err);
        goto failed;
    }
    
    if ([receivedData length] > 0) {
        self.responseDic = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableContainers error:&err];
        if (!self.responseDic) {
            NSLog(@"Error parsing JSON: %@", err);
            goto failed;
        }
    } else {
        NSLog(@"Error: no data returned :(");
    }

failed:
    return;
}

- (void)processAsyncRequest:(NSURLRequest *)request completionHandler:(void (^)(NSString *message))completionHandler;
{
    BUCNetworkEngine * __weak weakEngine = self;
    self.currentTask = [self.defaultSession dataTaskWithRequest:request
                                              completionHandler:
                        ^(NSData *data, NSURLResponse *response, NSError *error) {
                            NSString *errorMessage = nil;
                            if (error) {
                                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                                    if (httpResponse.statusCode == 500) errorMessage = @"服务器错误，请稍后再试";
                                    goto done;
                                } else {
                                    if (error.code == NSURLErrorTimedOut) errorMessage = @"服务器连接超时，请检查网络连接";
                                    goto done;
                                }
                            }
                            
                            if ([data length] > 0) {
                                weakEngine.responseDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                                if (!weakEngine.responseDic) {
                                    errorMessage = @"数据解析错误，请重新尝试";
                                    goto done;
                                }
                            } else {
                                errorMessage = @"无法加载数据，请重新尝试";
                            }
                            
                        done:
                            
                            completionHandler(errorMessage);
                        }];
    
    [self.currentTask resume];
}
@end

















