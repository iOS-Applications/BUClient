//
//  BUCThread.h
//  BUClient
//
//  Created by Joe Jeong on 2/14/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BUCForum.h"
#import "BUCPoster.h"

@interface BUCThread : NSObject
@property (nonatomic) BUCForum *forum;
@property (nonatomic) BUCPoster *poster;

@property (nonatomic) NSString *tid;
@property (nonatomic) NSString *title;
@property (nonatomic) NSInteger postCount;
@property (nonatomic) NSString *replyCount;
@property (nonatomic) NSString *dateline;
@end
