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


@implementation BUCRenderNode

- (instancetype)initWithString:(NSString *)string {
    self = [super init];
    
    if (self) {
        _isRichText = YES;
        _richText = [[NSMutableAttributedString alloc] initWithString:string];
    }
    
    return self;
}


- (instancetype)initWithRichText:(NSMutableAttributedString *)richText {
    self = [super init];
    
    if (self) {
        _isRichText = YES;
        _richText = richText;
    }
    
    return self;
}


- (instancetype)initWithAttachment:(BUCImageAttachment *)attachment {
    self = [super init];
    
    if (self) {
        _isRichText = YES;
        _isRichText = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
        _attachmentList = [NSMutableArray arrayWithObject:attachment];
    }
    
    return self;
}


- (void)addAttachment:(BUCImageAttachment *)attachment
{
    if (self.attachmentList) {
        [self.attachmentList addObject:attachment];
    } else {
        self.attachmentList = [NSMutableArray arrayWithObject:attachment];
    }
}


- (void)addChildNode:(BUCRenderNode *)child {
    if (child.nodeType == BUCRichTextNode ||
        child.nodeType == BUCAttachmentNode) {
        
    }
}


@end


@implementation BUCPost


@end


@implementation BUCLinkAttribute


@end


@implementation BUCTextBlockAttribute



@end













