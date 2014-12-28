@interface UINavigationController (autoRotate)

- (BOOL)shouldAutorotate;
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation;

@end

@interface BUCRootController : UITableViewController

- (void)displayLogout;

@end
