//
//  BUCContentViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/22/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCContentController.h"
#import "BUCRootController.h"

@interface BUCContentController ()

@property (nonatomic, weak) IBOutlet UIView *LOADINGVIEW;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *ACTIVITYINDICATOR;
@property (nonatomic, weak) BUCRootController *ROOTCONTROLLER;

@end

@implementation BUCContentController
#pragma mark - overrided methods
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.ROOTCONTROLLER = (BUCRootController *)self.parentViewController;
    
    // set up loading view
    self.LOADINGVIEW.center = self.view.center;
    self.LOADINGVIEW.layer.cornerRadius = 10.0f;
    
    [self performSegueWithIdentifier:@"segueToPostList" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (![self.childViewControllers count])
    {
        [self addChildViewController:segue.destinationViewController];
        ((UIViewController *)segue.destinationViewController).view.frame = self.view.frame;
        [self.view addSubview:((UIViewController *)segue.destinationViewController).view];
        [segue.destinationViewController didMoveToParentViewController:self];
    } else
    {
        UIViewController *fromVC = [self.childViewControllers lastObject];
        [self swapFromViewController:fromVC toViewController:segue.destinationViewController];
    }
}

#pragma mark - public methods
- (void)displayLoading
{
    [self.ACTIVITYINDICATOR startAnimating];
    [self.view bringSubviewToFront:self.LOADINGVIEW];
}

- (void)hideLoading
{
    [self.ACTIVITYINDICATOR stopAnimating];
    [self.view sendSubviewToBack:self.LOADINGVIEW];
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

#pragma mark - anctions and unwind methods
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

@end
























