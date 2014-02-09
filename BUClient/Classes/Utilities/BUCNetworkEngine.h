//
//  BUCNetworkEngine.h
//  BUClient
//
//  Created by Joe Jeong on 1/25/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BUCNetworkEngine : NSObject

@property BOOL hostIsOn;

@property NSDictionary *responseDic;

+ (BUCNetworkEngine *)sharedInstance;

- (NSString *)processSyncRequest:(NSDictionary *)requestDic;
- (void)processAsyncRequest:(NSDictionary *)requestDic completionHandler:(void (^)(NSString *message))completionHandler;

- (void)cancelCurrentTask;
- (void)suspendCurrentTask;
- (void)resumeCurrentTask;

- (BOOL)checkNetworkStatus;

@end
