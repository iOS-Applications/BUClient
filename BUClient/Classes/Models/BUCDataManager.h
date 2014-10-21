//
//  BUCDataManager.h
//  BUClient
//
//  Created by Joe Jeong on 10/20/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ArrayBlock)(NSArray *list);
typedef void(^FailBlock) (NSError *error);

@interface BUCDataManager : NSObject
+ (BUCDataManager *)sharedInstance;
- (void)getFrontListOnSuccess:(ArrayBlock)arrayBlock onFail:(FailBlock)failBlock;
@end
