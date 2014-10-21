//
//  BUCPost.h
//  BUClient
//
//  Created by Joe Jeong on 10/20/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BUCPost : NSObject

@property (nonatomic) BUCPost *parent;

@property (nonatomic) NSString *pid;
@property (nonatomic) NSString *fid;
@property (nonatomic) NSString *fname;

@property (nonatomic) NSString *user;
@property (nonatomic) NSString *uid;

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *content;
@property (nonatomic) NSString *dateline;

@property (nonatomic) NSString *childCount;

@property (nonatomic) NSInteger index;

@end
