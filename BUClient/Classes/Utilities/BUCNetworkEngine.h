//
//  BUCNetworkEngine.h
//  BUClient
//
//  Created by Joe Jeong on 1/25/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^networkResultBlock) (NSDictionary *);
typedef void(^networkErrorBlock) (NSError *error);

@interface BUCNetworkEngine : NSObject

@property (readonly, nonatomic) NSString *baseUrl;

+ (BUCNetworkEngine *)sharedInstance;
- (void)processRequest:(NSMutableURLRequest *)request
                  json:(NSDictionary *)json
              onResult:(networkResultBlock)resultBlock
               onError:(networkErrorBlock)errorBlock;
@end
