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

@property (nonatomic) UIView *LOADINGVIEW;
@property (nonatomic) UIActivityIndicatorView *ACTIVITYINDICATOR;
@property (nonatomic, weak) BUCRootController *ROOTCONTROLLER;

@end

@implementation BUCContentController
#pragma mark - overrided methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.ROOTCONTROLLER = (BUCRootController *)(self.parentViewController).parentViewController;
    
    // set up loading view
    UIView *loadingView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 140.0f, 140.0f)];
    loadingView.center = self.view.center;
    loadingView.layer.cornerRadius = 10.0f;
    loadingView.backgroundColor = [UIColor blackColor];
    loadingView.alpha = 0.5f;
    self.LOADINGVIEW = loadingView;
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.center = CGPointMake(70.0f, 40.0f);
    [loadingView addSubview:activityIndicator];
    self.ACTIVITYINDICATOR = activityIndicator;
    
    UILabel *text = [[UILabel alloc] init];
    text.text = @"Please wait...";
    [text sizeToFit];
    text.center = CGPointMake(75.0f, 100.0f);
    [text setTextColor:[UIColor whiteColor]];
    [loadingView addSubview:text];
    
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
    UIView *loadingView = self.LOADINGVIEW;
    UIActivityIndicatorView *activityIndicator = self.ACTIVITYINDICATOR;
    
    [activityIndicator startAnimating];
    [self.view addSubview:loadingView];
}

- (void)hideLoading
{
    UIView *loadingView = self.LOADINGVIEW;
    UIActivityIndicatorView *activityIndicator = self.ACTIVITYINDICATOR;
    
    [loadingView removeFromSuperview];
    [activityIndicator stopAnimating];
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
- (IBAction)showMenu:(id)sender
{
    BUCRootController *rootController = self.ROOTCONTROLLER;
    
    [rootController showMenu];
}

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
























