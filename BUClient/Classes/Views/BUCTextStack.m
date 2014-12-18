#import "BUCTextStack.h"
#import "BUCModels.h"
#import "BUCConstants.h"


@interface BUCTextContainer ()
@property (nonatomic) BOOL isBlock;
@end

@implementation BUCTextContainer
- (CGRect)lineFragmentRectForProposedRect:(CGRect)proposedRect
                                  atIndex:(NSUInteger)characterIndex
                         writingDirection:(NSWritingDirection)baseWritingDirection
                            remainingRect:(CGRect *)remainingRect {
    
    CGRect output = [super lineFragmentRectForProposedRect:proposedRect
                                                   atIndex:characterIndex
                                          writingDirection:baseWritingDirection
                                             remainingRect:remainingRect];

    NSUInteger length = self.layoutManager.textStorage.length;

    BUCTextBlockAttribute *blockAttribute;
    if (characterIndex < length) {
        blockAttribute = [self.layoutManager.textStorage attribute:BUCTextBlockAttributeName atIndex:characterIndex effectiveRange:NULL];
    }
    
    if (blockAttribute) {
        output = CGRectInset(output, blockAttribute.padding, 0.0f);
        if (!self.isBlock) {
            self.isBlock = YES;
            output = CGRectOffset(output, 0.0f, blockAttribute.padding);
        }
    } else if (self.isBlock) {
        self.isBlock = NO;
    }

    return output;
}


@end


@implementation BUCLayoutManager
- (void)drawBackgroundForGlyphRange:(NSRange)glyphsToShow atPoint:(CGPoint)origin {    
    NSArray *blockList = [self.textStorage attribute:BUCTextBlockListAttributeName atIndex:0 effectiveRange:NULL];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, BUCBorderWidth);
    [[UIColor colorWithWhite:0.98f alpha:1.0f] setFill];
    CGContextSaveGState(context);
    BUCTextContainer *textContainer = [self.textContainers lastObject];

    for (BUCTextBlockAttribute *blockAttribute in [blockList reverseObjectEnumerator]) {
        if (blockAttribute.noBackground) {
            continue;
        }
        
        CGRect frame = CGRectIntegral([self boundingRectForGlyphRange:blockAttribute.range inTextContainer:textContainer]);
        frame = CGRectInset(frame, -BUCDefaultMargin, -BUCDefaultMargin);
        if (blockAttribute.backgroundColor) {
            [blockAttribute.backgroundColor setFill];
            CGContextFillRect(context, frame);
            CGContextRestoreGState(context);
        } else {
            CGContextFillRect(context, frame);
        }

        CGContextStrokeRect(context, frame);
    }
}


@end