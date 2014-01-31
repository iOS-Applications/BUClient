//
//  BUCEventInterceptWindow.h
//  BUClient
//
//  Created by Joe Jeong on 2/1/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EventInterceptWindowDelegate
- (void)interceptEvent:(UIEvent *)event;
@end

@interface BUCEventInterceptWindow : UIWindow

@property (nonatomic, assign) id <EventInterceptWindowDelegate> eventInterceptDelegate;

@end
