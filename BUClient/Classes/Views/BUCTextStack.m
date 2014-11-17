
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
    NSLog(@"shit happened");
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
        
        x = x + leftMargin + borderWidth + leftPadding;
        width = width - (leftPadding + leftMargin) * 2;
        if (!self.isBlock) {
            self.isBlock = YES;
            topMargin = blockAttribute.topMargin;
            topPadding = blockAttribute.topPadding;
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

- (void)drawBackgroundForGlyphRange:(NSRange)glyphsToShow atPoint:(CGPoint)origin {
    BUCLinkAttribute *linkAttribute = [self.textStorage attribute:BUCLinkAttributeName atIndex:glyphsToShow.location effectiveRange:NULL];
    if (linkAttribute) {
        CGRect frame = [self boundingRectForGlyphRange:linkAttribute.range inTextContainer:[self.textContainers lastObject]];
        frame = CGRectInset(frame, -2.0f, -2.0f);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:2.0f];
        [[UIColor colorWithWhite:0.95f alpha:1.0f] setFill];
        [path fill];
        
        return;
    }

    NSArray *blockList = [self.textStorage attribute:BUCTextBlockListAttributeName atIndex:0 effectiveRange:NULL];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 0.5f);
    [[UIColor lightGrayColor] setStroke];
    [[UIColor colorWithWhite:0.95f alpha:1.0f] setFill];
    
    for (BUCTextBlockAttribute *blockAttribute in blockList) {
        CGRect frame = [self boundingRectForGlyphRange:blockAttribute.range inTextContainer:[self.textContainers lastObject]];
        frame = CGRectInset(frame, -blockAttribute.leftPadding - blockAttribute.borderWidth, -blockAttribute.topPadding - blockAttribute.borderWidth);
        CGContextFillRect(context, frame);
        frame = CGRectInset(frame, -0.5f, -0.5f);
        CGContextStrokeRect(context, frame);
    }
}


@end