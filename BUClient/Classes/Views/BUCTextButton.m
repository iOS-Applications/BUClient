#import "BUCTextButton.h"


@implementation BUCTextButton
- (void)setTitle:(NSAttributedString *)title {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.attributedText = title;
    titleLabel.textColor = titleLabel.tintColor;
    
    [titleLabel sizeToFit];
    self.frame = titleLabel.frame;
    [self addSubview:titleLabel];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.alpha = 0.5f;
}



- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    BUCTextButton * __weak weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^(void) {
        weakSelf.alpha = 1.0f;
    }];
    [super touchesEnded:touches withEvent:event];

}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.alpha = 1.0f;
}


@end
