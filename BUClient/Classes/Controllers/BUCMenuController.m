#import "BUCMenuController.h"
#import "BUCConstants.h"


@interface BUCMenuController ()


@end


@implementation BUCMenuController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}


- (IBAction)shit:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:BUCMainStoryboardPath bundle:nil];
    UIViewController *postListController = [storyboard instantiateViewControllerWithIdentifier:BUCPostListControllerStoryboardID];
    [(UINavigationController *)self.parentViewController pushViewController:postListController animated:YES];
}


@end
