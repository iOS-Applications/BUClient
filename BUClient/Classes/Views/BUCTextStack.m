
#import "BUCTextStack.h"
#import "BUCModels.h"
#import "BUCConstants.h"


@interface BUCTextContainer ()


@property (nonatomic) BOOL isBlock;


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
    CGRect output = [super lineFragmentRectForProposedRect:proposedRect atIndex:characterIndex writingDirection:baseWritingDirection remainingRect:remainingRect];

    NSUInteger length = self.layoutManager.textStorage.length;

    BUCTextBlockAttribute *blockAttribute;
    if (characterIndex < length) {
        blockAttribute = [self.layoutManager.textStorage attribute:BUCTextBlockAttributeName atIndex:characterIndex effectiveRange:NULL];
    }
    
    CGFloat x = CGRectGetMinX(output);
    CGFloat y = CGRectGetMinY(output);
    CGFloat width = CGRectGetWidth(output);
    CGFloat height= CGRectGetHeight(output);
    
    if (blockAttribute) {
        x = x + blockAttribute.padding;
        width = width - 2 * blockAttribute.padding;
        if (!self.isBlock) {
            self.isBlock = YES;
            y = y + blockAttribute.padding;
        }
    } else if (self.isBlock) {
        self.isBlock = NO;
    }
    
    return CGRectMake(x, y, width, height);
}


@end


@interface BUCLayoutManager ()

@property (nonatomic) UIColor *backgroundColor;
@property (nonatomic) UIColor *borderColor;

@end


@implementation BUCLayoutManager


- (instancetype)init {
    self = [super init];
    
    if (self) {
        _backgroundColor = [UIColor colorWithWhite:0.95f alpha:1.0f];
        _borderColor = [UIColor lightGrayColor];
    }
    
    return self;
}


- (void)drawBackgroundForGlyphRange:(NSRange)glyphsToShow atPoint:(CGPoint)origin {
    [self.borderColor setStroke];
    
    NSArray *blockList = [self.textStorage attribute:BUCTextBlockListAttributeName atIndex:0 effectiveRange:NULL];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, BUCBorderWidth);
    BUCTextContainer *textContainer = [self.textContainers lastObject];
    
    for (BUCTextBlockAttribute *blockAttribute in [blockList reverseObjectEnumerator]) {
        if (blockAttribute.backgroundColor) {
            [blockAttribute.backgroundColor setFill];
        } else {
            [self.backgroundColor setFill];
        }
        
        CGRect frame = [self boundingRectForGlyphRange:blockAttribute.range inTextContainer:textContainer];
        frame = CGRectInset(frame, -BUCDefaultPadding, -BUCDefaultPadding);
        CGContextFillRect(context, frame);
        CGContextStrokeRect(context, frame);
    }
}


@end