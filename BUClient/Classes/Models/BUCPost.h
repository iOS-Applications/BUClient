//
//  BUCPost.h
//  BUClient
//
//  Created by Joe Jeong on 2/14/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BUCThread.h"
#import "BUCPoster.h"
@interface BUCPost : NSObject
@property (nonatomic) BUCThread *thread;
@property (nonatomic) BUCPoster *poster;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *message;
@property (nonatomic) NSString *dateline;
@property (nonatomic) NSInteger index;
@end
