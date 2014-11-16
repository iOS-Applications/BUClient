#import "BUCTextView.h"
#import "BUCConstants.h"
#import "BUCTextStack.h"
#import "BUCDataManager.h"


@interface BUCTextView () <NSLayoutManagerDelegate>


@property (nonatomic) NSTextStorage *textStorage;
@property (nonatomic) NSLayoutManager *layoutManager;
@property (nonatomic) NSTextContainer *textContainer;

@property (nonatomic) NSRange selectedRange;
@property (nonatomic) UIColor *selectedBackgroundColor;


@end


@implementation BUCTextView


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        _leftPadding = 5.0f;
        _topPadding = 5.0f;
        _bottomPadding = 10.0f;
        _textStorage = [[NSTextStorage alloc] init];
        _layoutManager = [[BUCLayoutManager alloc] init];
        [_textStorage addLayoutManager:_layoutManager];
        _textContainer = [[BUCTextContainer alloc] initWithSize:CGSizeMake(CGRectGetWidth(frame), FLT_MAX)];
        _textContainer.lineFragmentPadding = 0;
        [_layoutManager addTextContainer:_textContainer];
        _layoutManager.delegate = self;
        _selectedBackgroundColor = [UIColor colorWithWhite:0.95f alpha:1.0f];
    }
    
    return self;
}


- (void)layoutSubviews {
    NSArray *attachmentList = [self.textStorage attribute:BUCAttachmentListAttributeName atIndex:0 effectiveRange:NULL];
    for (BUCImageAttachment *attachment in attachmentList) {
        CGRect frame = [self.layoutManager boundingRectForGlyphRange:NSMakeRange(attachment.glyphIndex, 1) inTextContainer:self.textContainer];
        frame = CGRectOffset(frame, self.leftPadding, self.topPadding);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        if (attachment.image) {
            imageView.image = attachment.image;
        } else {
            [[BUCDataManager sharedInstance] getImageFromUrl:attachment.url onSuccess:^(UIImage *image) {
                imageView.image = image;
            }];
        }
        
        [self addSubview:imageView];
    }
}


- (void)drawRect:(CGRect)rect {
    CGPoint origin = CGPointMake(self.leftPadding, self.topPadding);
    NSRange glyphRange = NSMakeRange(0, self.textStorage.length);
    [self.layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:origin];
    [self.layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:origin];
    
    CGSize size = [self sizeThatFits:CGSizeZero];
    CGPoint borderStart = CGPointMake(self.leftPadding, size.height);
    CGPoint borderEnd = CGPointMake(CGRectGetWidth(self.frame) - self.leftPadding, size.height);
    UIBezierPath *borderPath = [UIBezierPath bezierPath];
    [[UIColor lightGrayColor] setStroke];
    [borderPath moveToPoint:borderStart];
    [borderPath addLineToPoint:borderEnd];
    [borderPath stroke];
}


- (CGSize)sizeThatFits:(CGSize)size {
    [self.layoutManager ensureLayoutForTextContainer:self.textContainer];
    CGRect frame = [self.layoutManager usedRectForTextContainer:self.textContainer];
    CGFloat height = ceilf(CGRectGetHeight(frame)) + self.topPadding + self.bottomPadding;
    
    return CGSizeMake(CGRectGetWidth(self.frame), height);
}


#pragma mark - accessors
- (void)setRichText:(NSAttributedString *)richText {
    self.richText = richText;
    [self.textStorage setAttributedString:richText];
}


- (void)setSelectedRange:(NSRange)range {
    if (self.selectedRange.length && !NSEqualRanges(self.selectedRange, range)) {
        [self.textStorage removeAttribute:NSBackgroundColorAttributeName range:self.selectedRange];
    }
    
    if (range.length) {
        [self.textStorage addAttribute:NSBackgroundColorAttributeName value:self.selectedBackgroundColor range:range];
    }
    
    self.selectedRange = range;
    
    [self setNeedsDisplay];
}


#pragma mark - touch event handling
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint location = [[touches anyObject] locationInView:self];
    NSUInteger touchedCharIndex = [self.layoutManager glyphIndexForPoint:location inTextContainer:self.textContainer];
    
    BUCLinkAttribute *linkAttribute = [self.textStorage attribute:BUCLinkAttributeName atIndex:touchedCharIndex effectiveRange:NULL];
    
    if (linkAttribute) {
        self.selectedRange = linkAttribute.range;
    }
    
    BUCImageAttachment *attachment = [self.textStorage attribute:NSAttachmentAttributeName atIndex:touchedCharIndex effectiveRange:NULL];
    
    if (attachment) {
        // handle atta
    }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.selectedRange = NSMakeRange(0, 0);
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint location = [[touches anyObject] locationInView:self];
    NSUInteger touchedCharIndex = [self.layoutManager glyphIndexForPoint:location inTextContainer:self.textContainer];

    BUCLinkAttribute *linkAttribute = [self.textStorage attribute:BUCLinkAttributeName atIndex:touchedCharIndex effectiveRange:NULL];
    BUCImageAttachment *attachment = [self.textStorage attribute:NSAttachmentAttributeName atIndex:touchedCharIndex effectiveRange:NULL];
    
    if (linkAttribute) {
        // handle link tapping
        self.linkTapHandler(linkAttribute);
        self.selectedRange = NSMakeRange(0, 0);
    } else if (attachment) {
        // handle image tapping
        self.imageTapHander(attachment);
    }
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



















