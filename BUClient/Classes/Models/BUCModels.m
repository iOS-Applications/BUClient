#import "BUCModels.h"
#import "BUCConstants.h"


@implementation BUCPost
- (instancetype)initWithTextStack {
    self = [super init];
    if (self) {
        _textStorage = [[NSTextStorage alloc] init];
        _layoutManager = [[NSLayoutManager alloc] init];
        [_textStorage addLayoutManager:_layoutManager];
        _textContainer = [[BUCTextContainer alloc] init];
        _textContainer.lineFragmentPadding = 0;
        [_layoutManager addTextContainer:_textContainer];
        _layoutManager.delegate = self;
    }
    
    return self;
}


- (BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex {
    BUCLinkAttribute *linkAttribute = [self.textStorage attribute:BUCLinkAttributeName atIndex:charIndex effectiveRange:NULL];
    if (linkAttribute && (linkAttribute.range.location < charIndex && charIndex < linkAttribute.range.length + linkAttribute.range.location)) {
        return NO;
    }
    return YES;
}

@end

@implementation BUCRichText
- (instancetype)init {
    self = [super init];
    if (self) {
        _richText = [[NSMutableAttributedString alloc] init];
    }
    return self;
}
@end
@implementation BUCImageAttachment @end
@implementation BUCLinkAttribute @end
@implementation BUCTextBlockAttribute @end













