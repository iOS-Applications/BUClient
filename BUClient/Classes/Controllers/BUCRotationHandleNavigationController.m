#import "BUCRotationHandleNavigationController.h"

@interface BUCRotationHandleNavigationController ()

@end

@implementation BUCRotationHandleNavigationController

-(BOOL)shouldAutorotate {
    UIViewController *top = self.topViewController;
    return [top shouldAutorotate];
}

@end
