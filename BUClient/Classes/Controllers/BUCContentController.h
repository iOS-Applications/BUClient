#import <UIKit/UIKit.h>

@interface BUCContentController : UINavigationController


- (void)displayLoading;
- (void)hideLoading;

- (void)alertMessage:(NSString *)message;


@end
