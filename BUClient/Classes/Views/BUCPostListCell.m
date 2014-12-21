#import "BUCPostListCell.h"

@implementation BUCPostListCell
- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    if (self.imageList && self.imageList.count > 0) {
        [self.imageList makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.imageList removeAllObjects];
    }
    self.background.image = nil;
}

@end
