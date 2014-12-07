#import "BUCPostListCell.h"


@implementation BUCPostListCell


#pragma mark - overrided methods

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.layer.borderWidth = 0.5f;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame {
    frame.origin.x = 8.0f;
    frame.size.width = [UIScreen mainScreen].bounds.size.width - 2 * 8.0f;
    [super setFrame:frame];
}


- (void)awakeFromNib {
    self.author.titleLabel.opaque = YES;
    self.author.titleLabel.backgroundColor = [UIColor whiteColor];
    self.author.titleLabel.clearsContextBeforeDrawing = NO;
    self.author.titleLabel.autoresizesSubviews = NO;
    
    self.forum.titleLabel.opaque = YES;
    self.forum.titleLabel.backgroundColor = [UIColor whiteColor];
    self.forum.titleLabel.clearsContextBeforeDrawing = NO;
    self.forum.titleLabel.autoresizesSubviews = NO;
    
    self.lastPoster.titleLabel.opaque = YES;
    self.lastPoster.titleLabel.backgroundColor = [UIColor whiteColor];
    self.lastPoster.titleLabel.clearsContextBeforeDrawing = NO;
    self.lastPoster.titleLabel.autoresizesSubviews = NO;
}


@end










