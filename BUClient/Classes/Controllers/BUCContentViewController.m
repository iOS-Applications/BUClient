//
//  BUCContentViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/22/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCContentViewController.h"

@interface BUCContentViewController ()
@property (strong, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;

@end

@implementation BUCContentViewController
#pragma mark - overrided methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.loadingView.center = self.view.center;
    self.loadingView.layer.cornerRadius = 10.0f;
    
    NSString *kUserLoginNotification = @"kUserLoginNotification";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bringUpFront) name:kUserLoginNotification object:nil];
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

- (void)alertMessage:(NSString *)message
{
    [[[UIAlertView alloc]
      initWithTitle:nil
      message:message
      delegate:self
      cancelButtonTitle:@"OK"
      otherButtonTitles:nil] show];
}

#pragma mark - unwind methods
- (IBAction)unwindToContent:(UIStoryboardSegue *)segue
{
    
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

- (void)bringUpFront
{
    [self performSegueWithIdentifier:@"segueToFront" sender:nil];
}

@end
