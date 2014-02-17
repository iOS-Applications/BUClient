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
- (NSError *)checkErr:(NSError *)error response:(NSURLResponse *)response
{
    static NSString *serverErrMsg = @"服务器错误，请稍后再试";
    static NSString *timeoutErrMsg = @"服务器连接超时，请检查网络连接或稍后再试";
    static NSString *cancelErrMsg = @"";
    static NSString *connectErrMsg = @"无法连接至服务器，请检查网络连接或稍后再试";
    static NSString *unknownErrMsg = @"未知错误";
    NSString *errMsg;
    
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if (httpResponse.statusCode == 500) errMsg = serverErrMsg;
    } else if (error.code == NSURLErrorTimedOut) {
        errMsg = timeoutErrMsg;
    } else if (error.code == NSURLErrorCancelled) {
        errMsg = cancelErrMsg;
    } else if (error.code == NSURLErrorCannotConnectToHost) {
        errMsg = connectErrMsg;
    }else {
        errMsg = unknownErrMsg;
    }
    
    return [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedDescriptionKey: errMsg}];
}

- (NSURLRequest *)requestWithUrl:(NSString *)url json:(NSMutableDictionary *)json
{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];

    req.HTTPMethod = @"POST";
    NSError *error = nil;
    NSMutableDictionary *dataJson = [[NSMutableDictionary alloc] init];
    for (NSString *key in json) {
        [dataJson setObject:[[json objectForKey:key] urlencode] forKey:key];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:dataJson options:0 error:&error];
    if (!data) return nil;
    req.HTTPBody = data;

    return req;
}
@end
