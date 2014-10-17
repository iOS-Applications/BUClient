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
#import "BUCPoster.h"
#import "NSObject+BUCTools.h"

@interface BUCNetworkEngine ()
{
    Reachability *lanHostReach;
    Reachability *wanHostReach;
}

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
    dispatch_once(&onceSecurePredicate,^{
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
        
        _baseUrl = @"http://out.bitunion.org/open_api/bu_%@.php";
    }
    
    return self;
}

#pragma mark - public methods
- (NSURLSessionDataTask *)processRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSError *))completionHandler
{
    BUCNetworkEngine * __weak weakSelf = self;
    NSURLSessionDataTask *task = [self.defaultSession dataTaskWithRequest:request
                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                            if (error) {
                                                                error = [weakSelf checkErr:error response:response];
                                                            }
                                                  
                                                            completionHandler(data, error);
                                                        }];
    [task resume];
    return task;
}

@end















