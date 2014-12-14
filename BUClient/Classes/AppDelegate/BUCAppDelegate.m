#import "BUCAppDelegate.h"

@interface BUCAppDelegate ()

@property (nonatomic) UIAlertView *alertView;
@property (nonatomic) UIActivityIndicatorView *loadingView;
@property (nonatomic) UIView *loadingWindow;


@end

@implementation BUCAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.alertView = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    [self.window addSubview:self.loadingView];
    self.loadingView.center = self.window.center;
    [self.window addSubview:self.loadingView];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self.window bringSubviewToFront:self.loadingView];
}


- (void)alertWithMessage:(NSString *)message {
    self.alertView.message = message;
    [self.alertView show];
}


- (void)displayLoading {
    [self.loadingView startAnimating];
}


- (void)hideLoading {
    [self.loadingView stopAnimating];
}

@end





















