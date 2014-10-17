//
//  BUCNetworkEngine.h
//  BUClient
//
//  Created by Joe Jeong on 1/25/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BUCNetworkEngine : NSObject

@property (readonly, nonatomic) NSString *baseUrl;

+ (BUCNetworkEngine *)sharedInstance;

- (NSURLSessionDataTask *)processRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSError *error))completionHandler;

@end
