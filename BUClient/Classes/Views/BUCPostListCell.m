#import "BUCPostListCell.h"

@implementation BUCPostListCell
- (void)awakeFromNib {
    self.contentView.layer.contentsScale = [UIScreen mainScreen].scale;
}


- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    if (self.imageList && self.imageList.count > 0) {
        [self.imageList makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.imageList removeAllObjects];
    }
}

@end
