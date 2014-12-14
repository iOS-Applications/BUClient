#import <UIKit/UIKit.h>


@interface BUCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)alertWithMessage:(NSString *)message;
- (void)displayLoading;
- (void)hideLoading;

@end
