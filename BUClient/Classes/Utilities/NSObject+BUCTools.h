//
//  NSObject+BUCTools.h
//  BUClient
//
//  Created by Joe Jeong on 2/16/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (BUCTools)
- (NSURLRequest *)requestWithUrl:(NSString *)url json:(NSDictionary *)json;
@end
