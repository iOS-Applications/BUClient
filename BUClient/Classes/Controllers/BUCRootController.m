#import "BUCRootController.h"
#import "BUCConstants.h"
#import "BUCDataManager.h"


@interface BUCRootController ()

@end


@implementation BUCRootController
- (IBAction)forumList:(id)sender {
    UIViewController *forumListController = [self.storyboard instantiateViewControllerWithIdentifier:@"BUCForumListController"];
    [self presentViewController:forumListController animated:YES completion:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![BUCDataManager sharedInstance].loggedIn) {
        UIViewController *loginController = [self.storyboard instantiateViewControllerWithIdentifier:@"BUCLoginController"];
        [self presentViewController:loginController animated:YES completion:nil];
    }
}


- (IBAction)shit:(id)sender {
    UIViewController *postListController = [self.storyboard instantiateViewControllerWithIdentifier:BUCPostListControllerStoryboardID];
    [(UINavigationController *)self.parentViewController pushViewController:postListController animated:YES];
}


@end
