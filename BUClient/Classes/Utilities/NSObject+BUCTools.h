//
//  NSObject+BUCTools.h
//  BUClient
//
//  Created by Joe Jeong on 2/16/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+NSString_Extended.h"

@interface NSObject (BUCTools)
- (NSURLRequest *)requestWithUrl:(NSString *)url json:(NSDictionary *)json error:(NSError **)error;
@end
