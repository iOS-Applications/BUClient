#import "BUCAppDelegate.h"


@implementation BUCAppDelegate
- (void)displayLoading {
    self.loadingView.center = self.window.center;
    self.loadingView.hidden = NO;
    [self.activityIndicator startAnimating];
}

- (void)hideLoading {
    self.loadingView.hidden = YES;
    [self.activityIndicator stopAnimating];
}

- (void)hideAlert {
    self.alertViewWindow.hidden = YES;
}

- (void)alertWithMessage:(NSString *)message {
    self.alertLabel.text = message;
    self.alertViewWindow.hidden = NO;
}

- (void)displayActionSheet {
    UIView *actionSheetWindow = self.actionSheetWindow;
    [actionSheetWindow layoutIfNeeded];
    self.actionSheetBottomSpace.constant = 0;
    [UIView animateWithDuration:0.3 animations:^{
        actionSheetWindow.alpha = 1.0f;
        [actionSheetWindow layoutIfNeeded];
    }];
}

- (void)hideActionSheet {
    UIView *actionSheetWindow = self.actionSheetWindow;
    [actionSheetWindow layoutIfNeeded];
    self.actionSheetBottomSpace.constant = -self.actionSheet.frame.size.height;
    [UIView animateWithDuration:0.3 animations:^{
        actionSheetWindow.alpha = 0.0f;
        [actionSheetWindow layoutIfNeeded];
    }];
}

@end





















