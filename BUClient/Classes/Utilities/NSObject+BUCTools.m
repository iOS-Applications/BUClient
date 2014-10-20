//
//  NSObject+BUCTools.m
//  BUClient
//
//  Created by Joe Jeong on 2/16/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "NSObject+BUCTools.h"
#import "NSString+NSString_Extended.h"

@implementation NSObject (BUCTools)

- (NSURLRequest *)requestWithUrl:(NSString *)url json:(NSDictionary *)json
{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    req.HTTPMethod = @"POST";
    
    NSError *error = nil;
    NSMutableDictionary *dataJson = [[NSMutableDictionary alloc] init];
    for (NSString *key in json) {
        [dataJson setObject:[[json objectForKey:key] urlencode] forKey:key];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:dataJson options:0 error:&error];
    if (!data) {
        return nil;
    }
    
    req.HTTPBody = data;
    
    return req;
}


@end
