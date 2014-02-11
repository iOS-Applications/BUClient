//
//  BUCContentViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/22/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCContentViewController.h"
#import "BUCUser.h"

@interface BUCContentViewController ()
@property (strong, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;

@property BUCUser *user;
@end

@implementation BUCContentViewController
#pragma mark - overrided methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.user = [BUCUser sharedInstance];
    [self.user addObserver:self forKeyPath:@"isLoggedIn" options:NSKeyValueObservingOptionNew context:NULL];
    
    self.loadingView.center = self.view.center;
    self.loadingView.layer.cornerRadius = 10.0;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (![self.childViewControllers count]) {
        [self addChildViewController:segue.destinationViewController];
        ((UIViewController *)segue.destinationViewController).view.frame = self.view.frame;
        [self.view addSubview:((UIViewController *)segue.destinationViewController).view];
        [segue.destinationViewController didMoveToParentViewController:self];
    } else {
        UIViewController *fromVC = [self.childViewControllers lastObject];
        [self swapFromViewController:fromVC toViewController:segue.destinationViewController];
    }
}

#pragma mark - public methods
- (void)displayLoading
{
    [self.activityView startAnimating];
    [self.view addSubview:self.loadingView];
}

- (void)hideLoading
{
    [self.loadingView removeFromSuperview];
    [self.activityView stopAnimating];
}

- (void)removeChildController
{
    UIViewController *child = [self.childViewControllers lastObject];
    [child willMoveToParentViewController:nil];
    [child removeFromParentViewController];
}

#pragma mark - unwind methods
- (IBAction)unwindToContent:(UIStoryboardSegue *)segue
{
    
}

#pragma mark - key value observation handler methods
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.user.isLoggedIn) [self performSegueWithIdentifier:@"segueToFront" sender:nil];
}

#pragma mark - private methods
- (void)swapFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController
{
    toViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [fromViewController willMoveToParentViewController:nil];
    [self addChildViewController:toViewController];
    [self transitionFromViewController:fromViewController toViewController:toViewController duration:0.01 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil completion:^(BOOL finished) {
        [fromViewController removeFromParentViewController];
        [toViewController didMoveToParentViewController:self];
    }];
}

@end
