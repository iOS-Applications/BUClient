//
//  BUCContentViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/22/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCContentViewController.h"
#import "BUCMainViewController.h"

@interface BUCContentViewController ()

@end

@implementation BUCContentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self performSegueWithIdentifier:@"segueToFront" sender:nil];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self addChildViewController:segue.destinationViewController];
    ((UIViewController *)segue.destinationViewController).view.frame = self.view.frame;
    [self.view addSubview:((UIViewController *)segue.destinationViewController).view];
    [segue.destinationViewController didMoveToParentViewController:self];
}

//- (void)swapFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController
//{
//    toViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
//    
//    [fromViewController willMoveToParentViewController:nil];
//    [self addChildViewController:toViewController];
//    [self transitionFromViewController:fromViewController toViewController:toViewController duration:1.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil completion:^(BOOL finished) {
//        [fromViewController removeFromParentViewController];
//        [toViewController didMoveToParentViewController:self];
//    }];
//}

@end
