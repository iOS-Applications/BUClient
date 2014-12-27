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

