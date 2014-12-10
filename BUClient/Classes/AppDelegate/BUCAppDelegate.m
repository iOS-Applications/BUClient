#import "BUCAppDelegate.h"


@implementation BUCAppDelegate
- (void)displayLoading {
    self.loadingView.hidden = NO;
    [self.activityIndicator startAnimating];
}

- (void)hideLoading {
    self.loadingView.hidden = YES;
    [self.activityIndicator stopAnimating];
}

- (void)hideAlert {
    self.alertView.hidden = YES;
}

- (void)alertWithMessage:(NSString *)message {
    self.alertLabel.text = message;
    self.alertView.hidden = NO;
}

@end





















