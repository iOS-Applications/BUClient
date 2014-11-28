#import "BUCPostListCell.h"


@implementation BUCPostListCell


#pragma mark - overrided methods

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.layer.borderWidth = 0.3f;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.layer.backgroundColor = [UIColor whiteColor].CGColor;
        self.layer.cornerRadius = 4.0f;
    }
    
    return self;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.backgroundColor = [UIColor lightGrayColor];
    [super touchesBegan:touches withEvent:event];
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.backgroundColor = [UIColor whiteColor];
    [super touchesCancelled:touches withEvent:event];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    BUCPostListCell * __weak weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.backgroundColor = [UIColor whiteColor];
    }];
    
    CGPoint location = [[touches anyObject] locationInView:self];
    if ([self pointInside:location withEvent:event]) {
        [super touchesEnded:touches withEvent:event];
    }
}


@end