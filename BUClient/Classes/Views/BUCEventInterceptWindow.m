//
//  BUCEventInterceptWindow.m
//  BUClient
//
//  Created by Joe Jeong on 2/1/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCEventInterceptWindow.h"

@implementation BUCEventInterceptWindow
- (void)sendEvent:(UIEvent *)event
{
    [self.eventInterceptDelegate interceptEvent:event];
    [super sendEvent:event];
}
@end
