//
//  BUCRoundButtonView.m
//  BUClient
//
//  Created by Joe Jeong on 1/9/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCRoundButtonView.h"

@implementation BUCRoundButtonView
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGRect borderRect = CGRectMake(5.8339, 5.8339, 48.3322, 48.3322);
    borderRect = CGRectInset(borderRect, 1.0, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(context, 56.0/255.0, 117.0/255.0, 212.0/255.0, 1.0);
    CGContextSetRGBFillColor(context, 255.0/255.0, 255.0/255.0, 255.0/255.0, 1.0);
    CGContextSetLineWidth(context, 1.0);
    CGContextFillEllipseInRect (context, borderRect);
    CGContextStrokeEllipseInRect(context, borderRect);
    CGContextFillPath(context);
    
//    self.showsTouchWhenHighlighted = YES;
}


@end
