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


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.alpha = 1.0f;
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.alpha = 1.0f;
}


@end
