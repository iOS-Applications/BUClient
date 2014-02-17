//
//  BUCFrontPageTableCell.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCTableCell.h"

@implementation BUCTableCell
- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.content removeFromSuperview];
    [self.leftTopBtn removeFromSuperview];
    [self.leftBottomBtn removeFromSuperview];
    [self.rightBottomBtn removeFromSuperview];
    [self.timeStamp removeFromSuperview];
}

@end
