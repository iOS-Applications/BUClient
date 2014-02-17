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
@property (weak, nonatomic) IBOutlet UILabel *postIndex;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *dateline;
@property (weak, nonatomic) IBOutlet UILabel *credit;

@property (weak, nonatomic) UIWebView *content;
@property (weak, nonatomic) UIButton *leftTopBtn;
@property (weak, nonatomic) UIButton *leftBottomBtn;
@property (weak, nonatomic) UIButton *rightBottomBtn;
@property (weak, nonatomic) UILabel *timeStamp;

@property (nonatomic) CGFloat height;
@end
