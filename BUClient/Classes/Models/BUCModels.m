//
//  BUCModels.m
//  BUClient
//
//  Created by Joe Jeong on 11/14/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCModels.h"


@implementation BUCImageAttachment


@end


@implementation BUCPost
- (instancetype)init {
    self = [super init];
    
    if (self) {
        _textStorage = [[NSTextStorage alloc] init];
        _layoutManager = [[BUCLayoutManager alloc] init];
        [_textStorage addLayoutManager:_layoutManager];
        _textContainer = [[BUCTextContainer alloc] init];
        _textContainer.lineFragmentPadding = 0;
        [_layoutManager addTextContainer:_textContainer];
    }
    
    return self;
}

@end


@implementation BUCLinkAttribute


@end


@implementation BUCTextBlockAttribute



@end













