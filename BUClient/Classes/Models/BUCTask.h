//
//  BUCThing.h
//  BUClient
//
//  Created by Joe Jeong on 2/16/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BUCTask : NSObject
@property (nonatomic) NSString *url;
@property (nonatomic) NSMutableDictionary *json;

@property (nonatomic) NSData *data;
@property (nonatomic) NSDictionary *jsonData;

@property (nonatomic) NSInteger index;
@property (nonatomic) BOOL silence;

@property (nonatomic) NSURLSessionDataTask *task;
@property (nonatomic) NSMutableArray *taskList;

@property (nonatomic) BOOL done;
@end
