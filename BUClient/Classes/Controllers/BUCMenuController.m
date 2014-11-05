#import "BUCMenuController.h"
#import "BUCContentController.h"
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
    BUCContentController *contentController = (BUCContentController *)self.parentViewController;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:BUCMainStoryboardPath bundle:nil];
    UIViewController *postListController = [storyboard instantiateViewControllerWithIdentifier:BUCPostListControllerStoryboardID];
    [contentController pushViewController:postListController animated:YES];
}


@end
