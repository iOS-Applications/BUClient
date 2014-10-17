//
//  BUCHTMLParser.m
//  BUClient
//
//  Created by Joe Jeong on 2/18/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCHTMLParser.h"

@interface BUCHTMLParser ()
@property (nonatomic) NSString *template;
@end

@implementation BUCHTMLParser
+(BUCHTMLParser *)sharedInstance
{
    static BUCHTMLParser *sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        NSString *path = [[NSBundle mainBundle] bundlePath];
        path = [path stringByAppendingString:@"/default.html"];
        NSURL *baseURL = [NSURL fileURLWithPath:path];
        NSError *error = nil;
        
        _template = [[NSString alloc] initWithContentsOfURL:baseURL encoding:NSUTF8StringEncoding error:&error];
    }
    
    return self;
}

- (NSString *)parse:(NSString *)html
{
    NSString *result = [html stringByReplacingOccurrencesOfString:@"<br />" withString:@"<br>"];
    return [NSString stringWithFormat:self.template, result];
}
@end
