//
//  BUCCraftViewController.h
//  BUClient
//
//  Created by Joe Jeong on 2/1/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BUCEditorViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic) NSString *unwindSegueIdendifier;
@property (nonatomic) NSString *postSubject;
@end
