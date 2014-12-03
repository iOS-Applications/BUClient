#import "BUCRootController.h"
#import "BUCConstants.h"
#import "BUCLoginController.h"
#import "BUCDataManager.h"


@interface BUCRootController ()

@end


@implementation BUCRootController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}


- (void)viewDidAppear:(BOOL)animated {
    if (![BUCDataManager sharedInstance].loggedIn) {
        BUCLoginController *loginController = [self.storyboard instantiateViewControllerWithIdentifier:BUCLoginControllerStoryboardID];
        [self presentViewController:loginController animated:YES completion:nil];
    }
}


- (IBAction)shit:(id)sender {
    UIViewController *postListController = [self.storyboard instantiateViewControllerWithIdentifier:BUCPostListControllerStoryboardID];
    [(UINavigationController *)self.parentViewController pushViewController:postListController animated:YES];
}


@end
