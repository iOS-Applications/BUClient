#import "BUCAppDelegate.h"

@interface BUCAppDelegate ()

@property (nonatomic) UIAlertView *alertView;

@end

@implementation BUCAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.alertView = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    return YES;
}


- (void)alertWithMessage:(NSString *)message {
    self.alertView.message = message;
    [self.alertView show];
}


@end





















