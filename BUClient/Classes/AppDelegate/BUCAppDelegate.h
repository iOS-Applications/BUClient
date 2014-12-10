#import <UIKit/UIKit.h>


@interface BUCAppDelegate : UIResponder <UIApplicationDelegate>


@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) UIView *loadingView;
@property (nonatomic) UIActivityIndicatorView *activityIndicator;

@property (nonatomic) UIView *alertView;
@property (nonatomic) UILabel *alertLabel;

- (void)displayLoading;
- (void)hideLoading;
- (void)alertWithMessage:(NSString *)message;
- (void)hideAlert;


@end
