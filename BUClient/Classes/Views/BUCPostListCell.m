//
//  BUCPostListCell.m
//  BUClient
//
//  Created by zty on 12/15/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCPostListCell.h"

@implementation BUCPostListCell
- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    if (self.imageList && self.imageList.count > 0) {
        [self.imageList performSelector:@selector(removeFromSuperview)];
        [self.imageList removeAllObjects];
    }
}

@end
