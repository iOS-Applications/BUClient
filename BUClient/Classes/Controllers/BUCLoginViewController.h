//
//  IBULoginViewController.h
//  iBU
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BUCEventInterceptWindow.h"

@interface BUCLoginViewController : UIViewController <UITextFieldDelegate, EventInterceptWindowDelegate>
- (void)alertWithMessage:(NSString *)message;
@end
