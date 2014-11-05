#import "BUCRootController.h"
#import "BUCLoginController.h"
#import "BUCAuthManager.h"
#import "BUCConstants.h"


@implementation BUCRootController


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:BUCAppLaunchStateDefaultKey]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:BUCAppLaunchStateDefaultKey];
        [[NSUserDefaults standardUserDefaults] synchronize];

        if ([[NSUserDefaults standardUserDefaults] boolForKey:BUCUserLoginStateDefaultKey]) {
            [self loadContent];
        } else {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:BUCMainStoryboardPath bundle:nil];
            BUCLoginController *loginController = [storyboard instantiateViewControllerWithIdentifier:BUCLoginControllerStoryboardID];
            loginController.unwindIdentifier = BUCUnwindToRootStoryboardID;
            
            [self presentViewController:loginController animated:NO completion:nil];
        }
    }
}


#pragma mark - unwind callback
- (IBAction)unwindToRoot:(UIStoryboardSegue *)segue {
    [self loadContent];
}


#pragma mark - private methods
- (void)loadContent {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:BUCMainStoryboardPath bundle:nil];
    UIViewController *ContentController = [storyboard instantiateViewControllerWithIdentifier:BUCContentControllerStoryboardID];

    ContentController.view.frame = self.view.frame;
    [self addChildViewController:ContentController];
    [self.view addSubview:ContentController.view];
    [ContentController didMoveToParentViewController:self];
}


@end


























