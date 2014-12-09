//
//  BUCPostDetailCell.m
//  BUClient
//
//  Created by zty on 11/30/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCPostDetailCell.h"

@implementation BUCPostDetailCell
- (void)awakeFromNib {
    self.poster.titleLabel.opaque = YES;
    self.poster.titleLabel.backgroundColor = [UIColor whiteColor];
    self.poster.titleLabel.clearsContextBeforeDrawing = NO;
    self.poster.titleLabel.autoresizesSubviews = NO;
}


- (void)prepareForReuse {
    [super prepareForReuse];
    
    if (self.imageViewList && self.imageViewList.count > 0) {
        for (UIImageView *imageView in self.imageViewList) {
            [imageView removeFromSuperview];
        }
        self.imageViewList = nil;
    }
}


@end
