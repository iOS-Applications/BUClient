
#import "BUCTextStack.h"
#import "BUCModels.h"
#import "BUCConstants.h"


@interface BUCTextContainer ()


@property (nonatomic) BOOL isBlock;
@property (nonatomic) BUCTextBlockAttribute *blockAttribute;

@end


@implementation BUCTextContainer


- (instancetype)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    
    if (self) {
        _isBlock = NO;
    }
    
    return self;
}


- (CGRect)lineFragmentRectForProposedRect:(CGRect)proposedRect
                                  atIndex:(NSUInteger)characterIndex
                         writingDirection:(NSWritingDirection)baseWritingDirection
                            remainingRect:(CGRect *)remainingRect {
    
    CGRect output = [super lineFragmentRectForProposedRect:proposedRect atIndex:characterIndex writingDirection:baseWritingDirection remainingRect:remainingRect];;
    NSUInteger length = self.layoutManager.textStorage.length;
    
    BUCTextBlockAttribute *blockAttribute;
    if (characterIndex < length) {
        blockAttribute = [self.layoutManager.textStorage attribute:BUCTextBlockAttributeName atIndex:characterIndex effectiveRange:NULL];
    }
    
    CGFloat x = CGRectGetMinX(output);
    CGFloat y = CGRectGetMinY(output);
    CGFloat width = CGRectGetWidth(output);
    CGFloat height= CGRectGetHeight(output);
    CGFloat leftPadding = 0;
    CGFloat leftMargin = 0;
    CGFloat borderWidth = 0;
    CGFloat topMargin = 0;
    CGFloat topPadding = 0;
    
    
    if (blockAttribute) {
        leftMargin = blockAttribute.leftMargin;
        leftPadding = blockAttribute.leftPadding;
        borderWidth = blockAttribute.borderWidth;
        
        x = x + leftPadding + borderWidth + leftPadding;
        width = width - (leftPadding + leftMargin) * 2;
        if (!self.isBlock) {
            self.isBlock = YES;
            y = y + topMargin + borderWidth + topPadding;
            self.blockAttribute = blockAttribute;
        }
    } else if (self.isBlock) {
        topMargin = self.blockAttribute.topMargin;
        topPadding = self.blockAttribute.topPadding;
        borderWidth = self.blockAttribute.borderWidth;
        
        y = y + topMargin + borderWidth + topPadding;
        self.isBlock = NO;
    }
    
    return CGRectMake(x, y, width, height);
}


@end


@implementation BUCLayoutManager


- (void)fillBackgroundRectArray:(const CGRect *)rectArray
                          count:(NSUInteger)rectCount
              forCharacterRange:(NSRange)charRange
                          color:(UIColor *)color {
    
    BUCLinkAttribute *linkAttribute = [self.textStorage attribute:BUCLinkAttributeName atIndex:charRange.location effectiveRange:NULL];
    
    if (linkAttribute) {
        for (NSUInteger i = 0; i < rectCount; i = i + 1) {
            CGRect frame = rectArray[i];
            frame = CGRectInset(frame, -2.0f, -2.0f);
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:2.0f];
            [path fill];
        }

        return;
    }
    
    BUCTextBlockAttribute *blockAttribute = [self.textStorage attribute:BUCTextBlockAttributeName atIndex:charRange.location effectiveRange:NULL];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, blockAttribute.borderWidth);
    [blockAttribute.borderColor setStroke];
    
    for (NSUInteger i = 0; i < rectCount; i = i + 1) {
        CGRect frame = rectArray[i];
        frame = CGRectInset(frame, -blockAttribute.leftPadding, -blockAttribute.topPadding);
        CGContextFillRect(context, frame);
        frame = CGRectInset(frame, -blockAttribute.borderWidth, -blockAttribute.borderWidth);
        CGContextStrokeRect(context, frame);
    }
}


@end