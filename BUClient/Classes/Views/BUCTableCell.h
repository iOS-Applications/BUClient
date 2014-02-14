//
//  BUCFrontPageTableCell.h
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BUCRoundButtonView.h"

@interface BUCTableCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextView *title;
@property (weak, nonatomic) IBOutlet BUCRoundButtonView *replyCount;
@property (weak, nonatomic) IBOutlet UIButton *leftTopBtn;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;

@property (nonatomic) UIButton *leftBottomBtn;
@property (nonatomic) UIButton *rightBottomBtn;
@property (nonatomic) UILabel *timeStamp;
@property (nonatomic) CGFloat height;
@end
