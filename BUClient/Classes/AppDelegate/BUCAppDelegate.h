#import <UIKit/UIKit.h>


@interface BUCAppDelegate : UIResponder <UIApplicationDelegate>


@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) UIView *loadingView;
@property (nonatomic) UIActivityIndicatorView *activityIndicator;

@property (nonatomic) UIView *alertViewWindow;
@property (nonatomic) UILabel *alertLabel;

@property (nonatomic) UIView *actionSheetWindow;
@property (nonatomic) UIView *actionSheet;
@property (nonatomic) NSLayoutConstraint *actionSheetBottomSpace;

- (void)displayLoading;
- (void)hideLoading;
- (void)alertWithMessage:(NSString *)message;
- (void)hideAlert;
- (void)displayActionSheet;
- (void)hideActionSheet;

@end
