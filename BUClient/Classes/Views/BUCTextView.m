#import "BUCTextView.h"
#import "BUCConstants.h"



@interface BUCTextView () <NSLayoutManagerDelegate>


@end


@implementation BUCTextView


- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer{
    self = [super initWithFrame:frame textContainer:textContainer];
    
    if (self) {
        self.editable = NO;
        self.scrollEnabled = NO;
        self.opaque = YES;
        self.backgroundColor = [UIColor whiteColor];
        self.textContainerInset = UIEdgeInsetsZero;
        textContainer.lineFragmentPadding = 0;
        self.layoutManager.delegate = self;
    }
    
    return self;
}


- (void)drawRect:(CGRect)rect {
    CGPoint origin = CGPointMake(0, 0);
    NSRange glyphRange = NSMakeRange(0, self.textStorage.length);
    [self.layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:origin];
    [self.layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:origin];
}

- (void)foo {
    CGSize size = [self sizeThatFits:CGSizeZero];
    self.frame = CGRectMake(CGRectGetMinX(self.frame), CGRectGetMinY(self.frame), size.width, size.height);
}


- (CGSize)sizeThatFits:(CGSize)size {
    [self.layoutManager ensureLayoutForTextContainer:self.textContainer];
//    NSRange range = NSMakeRange(0, self.textStorage.length);
//    CGRect frame = [self.layoutManager boundingRectForGlyphRange:range inTextContainer:self.textContainer];
    
    CGRect frame = [self.layoutManager usedRectForTextContainer:self.textContainer];
    CGFloat height = ceilf(CGRectGetHeight(frame)) + 15.0;
    
    return CGSizeMake(CGRectGetWidth(self.frame), height);
}


#pragma mark - layout manager delegate
- (BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex {
    BUCLinkAttribute *linkAttribute = [layoutManager.textStorage attribute:BUCLinkAttributeName atIndex:charIndex effectiveRange:NULL];
    if (linkAttribute) {
        NSRange range = linkAttribute.range;
        if ((charIndex > range.location) && (charIndex <= NSMaxRange(range))) {
            return NO;
        } else {
            return YES;
        }
    }
    
    return YES;
}

@end



















