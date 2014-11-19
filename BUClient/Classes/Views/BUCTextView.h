#import <UIKit/UIKit.h>
#import "BUCModels.h"


typedef void (^LinkTapHandler) (BUCLinkAttribute *linkAttribute);
typedef void (^ImageTapHandler) (BUCImageAttachment *attachment);


@interface BUCTextView : UIView


- (instancetype)initWithFrame:(CGRect)frame richText:(NSAttributedString *)richText;

@property (nonatomic, copy) LinkTapHandler linkTapHandler;
@property (nonatomic, copy) ImageTapHandler imageTapHandler;

@end
