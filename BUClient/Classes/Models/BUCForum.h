//
//  BUCForum.h
//  BUClient
//
//  Created by Joe Jeong on 2/14/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BUCForum : NSObject
@property (nonatomic) NSString *fid;
@property (nonatomic) NSString *fname;
@property (nonatomic) NSString *type;
@property (nonatomic) NSInteger threadCount;
@end
