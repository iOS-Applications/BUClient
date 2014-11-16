#import <UIKit/UIKit.h>
#import "BUCModels.h"

typedef void(^ImageTapBlock) (BUCImageAttachment *);
typedef void(^LinkTapBlock) (BUCLinkAttribute *);

@interface BUCTextView : UIView


@property (nonatomic) NSAttributedString *richText;

@property (nonatomic) CGFloat leftPadding;
@property (nonatomic) CGFloat topPadding;
@property (nonatomic) CGFloat bottomPadding;

@property (nonatomic, copy) ImageTapBlock imageTapHander;
@property (nonatomic, copy) LinkTapBlock linkTapHandler;


@end
