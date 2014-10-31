//
//  BUCDataManager.h
//  BUClient
//
//  Created by Joe Jeong on 10/20/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ArrayBlock) (NSArray *);
typedef void(^ErrorBlock) (NSError *);
typedef void(^SuccessBlock) (NSDictionary *);

@interface BUCDataManager : NSObject
+ (BUCDataManager *)sharedInstance;
- (void)getFrontListOnSuccess:(ArrayBlock)arrayBlock onError:(ErrorBlock)errorBlock;
- (void)getPost:(NSString *)postID
           from:(NSString *)from
             to:(NSString *)to
      onSuccess:(ArrayBlock)arrayBlock
        onError:(ErrorBlock)errorBlock;
@end
