//
//  BUCNetworkEngine.h
//  BUClient
//
//  Created by Joe Jeong on 1/25/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^networkResultBlock) (NSDictionary *);
typedef void(^networkErrorBlock) (NSError *);

@interface BUCNetworkEngine : NSObject

+ (BUCNetworkEngine *)sharedInstance;

- (void)fetchDataFromURL:(NSString *)url
                    json:(NSDictionary *)json
                onResult:(networkResultBlock)resultBlock
                 onError:(networkErrorBlock)errorBlock;
@end
