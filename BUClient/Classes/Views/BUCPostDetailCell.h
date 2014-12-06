//
//  BUCPostDetailCell.h
//  BUClient
//
//  Created by zty on 11/30/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BUCPostDetailCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UIButton *poster;
@property (weak, nonatomic) IBOutlet UILabel *dateline;
@property (weak, nonatomic) IBOutlet UILabel *index;

@property (weak, nonatomic) UITextView *content;
@property (nonatomic) NSMutableArray *imageViewList;

@end
