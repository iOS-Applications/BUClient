#import "BUCTextView.h"
#import "BUCModels.h"
#import "BUCDataManager.h"
#import "BUCConstants.h"
#import "BUCTextStack.h"


@interface BUCTextView () <NSLayoutManagerDelegate>


@property (nonatomic) NSTextStorage *textStorage;
@property (nonatomic) BUCTextContainer *textContainer;
@property (nonatomic) BUCLayoutManager *layoutManager;

@property (nonatomic, assign) NSRange selectedRange;

@property (nonatomic) UIColor *linkBackgroundColor;


@end


@implementation BUCTextView


- (instancetype)initWithFrame:(CGRect)frame richText:(NSAttributedString *)richText {
    self = [super initWithFrame:frame];
    
    if (self) {
        _textStorage = [[NSTextStorage alloc] initWithAttributedString:richText];
        _textContainer = [[BUCTextContainer alloc] initWithSize:CGSizeMake(CGRectGetWidth(frame), FLT_MAX)];
        _layoutManager = [[BUCLayoutManager alloc] init];
        _textContainer.lineFragmentPadding = 0;
        _textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        _layoutManager.delegate = self;
        [_textStorage addLayoutManager:_layoutManager];
        [_layoutManager addTextContainer:_textContainer];
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
        
        _selectedRange = NSMakeRange(0, 0);
        _linkBackgroundColor = [UIColor colorWithWhite:0.95f alpha:1.0];
    }
    
    return self;
}


- (CGSize)sizeThatFits:(CGSize)size {
    [self.layoutManager ensureLayoutForTextContainer:self.textContainer];
    CGRect frame = [self.layoutManager usedRectForTextContainer:self.textContainer];
    CGFloat height = ceilf(CGRectGetHeight(frame)) + BUCDefaultPadding + BUCDefaultMargin;
    
    return CGSizeMake(CGRectGetWidth(self.frame), height);
}


- (void)drawRect:(CGRect)rect {
    CGPoint origin = CGPointMake(0, 0);

    if (self.selectedRange.length > 0) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:[self.layoutManager boundingRectForGlyphRange:self.selectedRange inTextContainer:self.textContainer] cornerRadius:5.0f];
        UIColor *backgroundColor = [self.textStorage attribute:NSBackgroundColorAttributeName atIndex:self.selectedRange.location effectiveRange:NULL];
        if (backgroundColor) {
            [backgroundColor setFill];
        } else {
            [[UIColor whiteColor] setFill];
        }
        
        [path fill];
        [self.layoutManager drawGlyphsForGlyphRange:self.selectedRange atPoint:origin];
        
        return;
    }
    
    NSRange glyphRange = NSMakeRange(0, self.textStorage.length);
    [self.layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:origin];
    [self.layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:origin];
    
    NSArray *attachmentList = [self.textStorage attribute:BUCAttachmentListAttributeName atIndex:0 effectiveRange:NULL];
    if (attachmentList) {
        [self.layoutManager ensureLayoutForTextContainer:self.textContainer];
        for (BUCImageAttachment *attachment in attachmentList) {
            CGRect frame = [self.layoutManager boundingRectForGlyphRange:NSMakeRange(attachment.glyphIndex, 1) inTextContainer:self.textContainer];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            if (attachment.gif) {
                imageView.image = attachment.gif;
            } else {
                [[BUCDataManager sharedInstance] getImageFromUrl:attachment.url onSuccess:^(UIImage *image) {
                    imageView.image = image;
                }];
            }
            
            [self addSubview:imageView];
        }
    }
}


#pragma mark - event handling
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    CGPoint location = [[touches anyObject] locationInView:self];
    NSUInteger index = [self.layoutManager glyphIndexForPoint:location inTextContainer:self.textContainer];
    BUCLinkAttribute *linkAttribute = [self.textStorage attribute:BUCLinkAttributeName atIndex:index effectiveRange:NULL];
    
    if (linkAttribute) {
        self.selectedRange = linkAttribute.range;
        [self.textStorage addAttribute:NSBackgroundColorAttributeName value:self.linkBackgroundColor range:self.selectedRange];
        [self setNeedsDisplayInRect:[self.layoutManager boundingRectForGlyphRange:self.selectedRange inTextContainer:self.textContainer]];
    }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    if (self.selectedRange.length > 0) {
        [self.textStorage removeAttribute:NSBackgroundColorAttributeName range:self.selectedRange];
        [self setNeedsDisplayInRect:[self.layoutManager boundingRectForGlyphRange:self.selectedRange inTextContainer:self.textContainer]];
    }
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];

    if (self.selectedRange.length > 0) {
        [self.textStorage removeAttribute:NSBackgroundColorAttributeName range:self.selectedRange];
        [self setNeedsDisplayInRect:[self.layoutManager boundingRectForGlyphRange:self.selectedRange inTextContainer:self.textContainer]];
    }
}


#pragma mark - layout manager delegate
- (BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex {
    BUCLinkAttribute *linkAttribute = [self.textStorage attribute:BUCLinkAttributeName atIndex:charIndex effectiveRange:NULL];
    if (linkAttribute) {
        NSRange range = linkAttribute.range;
        if ((charIndex > range.location) && (charIndex <= NSMaxRange(range))) {
            return NO;
        }
    }
    
    return YES;
}


@end



















