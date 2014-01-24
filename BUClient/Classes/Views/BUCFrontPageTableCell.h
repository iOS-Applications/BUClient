//
//  BUCFrontPageTableCell.h
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BUCRoundButtonView.h"

@interface BUCFrontPageTableCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *author;
@property (weak, nonatomic) IBOutlet UIButton *subforum;
@property (weak, nonatomic) IBOutlet UITextView *title;
@property (weak, nonatomic) IBOutlet BUCRoundButtonView *replyCount;
@end
