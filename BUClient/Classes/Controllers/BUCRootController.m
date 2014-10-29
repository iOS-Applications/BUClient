//
//  BUCRootViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/12/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCRootController.h"
#import "BUCLoginController.h"
#import "BUCMenuController.h"
#import "BUCContentController.h"
#import "BUCAuthManager.h"

#define MINTRANSLATION 130.0
#define MAXTRANSLATION 250.0

@interface BUCRootController ()
{
    CGPoint rightCenter;
    CGPoint leftCenter;
    CGPoint farRightCenter;
    
    UIPanGestureRecognizer *contentPanRecognizer;
    UITapGestureRecognizer *contentTapRecognizer;
}

@end

@implementation BUCRootController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    leftCenter = self.view.center;
    rightCenter = CGPointMake(leftCenter.x + MAXTRANSLATION, leftCenter.y);
    farRightCenter = CGPointMake(leftCenter.x + 320, leftCenter.y);
    
    contentPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    contentTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIView *menuWrapper = [self.view viewWithTag:100]; // 100 is tag value set in IB
    BUCMenuController *menuController = [storyboard instantiateViewControllerWithIdentifier:@"menuController"];
    menuController.view.frame = menuWrapper.frame;
    [self addChildViewController:menuController];
    [menuWrapper addSubview:menuController.view];
    [menuController didMoveToParentViewController:self];
    
    UIView *contentWrapper = [self.view viewWithTag:101]; // 101 is tag value set in IB
    contentWrapper.layer.shadowOpacity = 1.0;
    contentWrapper.layer.shadowRadius = 5.0;
    contentWrapper.layer.shadowPath = [UIBezierPath bezierPathWithRect:contentWrapper.bounds].CGPath;
    [contentWrapper addGestureRecognizer:contentPanRecognizer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isJustLaunched"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isJustLaunched"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"])
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            
            UIView *contentWrapper = [self.view viewWithTag:101];
            BUCContentController *contentController = [storyboard instantiateViewControllerWithIdentifier:@"contentController"];
            contentController.view.frame = contentWrapper.frame;
            [self addChildViewController:contentController];
            [contentWrapper addSubview:contentController.view];
            [contentController didMoveToParentViewController:self];
        }
        else
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            BUCLoginController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"loginController"];
            
            [self presentViewController:loginVC animated:NO completion:nil];
        }
    }
}

#pragma mark - public methods
- (void)showMenu
{
    UIView *contentWrapper = [self.view viewWithTag:101];
    [UIView animateWithDuration:0.75
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^(void) {
                         contentWrapper.center = rightCenter;
                     }
                     completion:nil];
    
    UIView *view = [contentWrapper.subviews lastObject];
    view.userInteractionEnabled = NO;
    [contentWrapper addGestureRecognizer:contentTapRecognizer];
}

- (void)switchContentWith:(NSString *)segueIdendifier completion:(void (^)(void))completeHandler
{
//    [UIView animateWithDuration:0.25
//                          delay:0
//                        options:UIViewAnimationOptionCurveEaseInOut
//                     animations:^{
//                         self.contentWrapper.center = farRightCenter;
//                     }
//                     completion:^(BOOL finished) {
//                         [UIView animateWithDuration:0.5
//                                               delay:0.05
//                                             options:UIViewAnimationOptionCurveEaseInOut
//                                          animations:^{
//                                              self.contentWrapper.center = leftCenter;
//                                          }
//                                          completion:^(BOOL finished) {
//                                              completeHandler();
//                                          }];
//                         
//                         [self.contentController performSegueWithIdentifier:segueIdendifier sender:nil];
//                     }];
//    
//    UIView *view = [self.contentWrapper.subviews lastObject];
//    view.userInteractionEnabled = YES;
//    [self.contentWrapper removeGestureRecognizer:self.contentTapRecognizer];
}

- (void)hideMenu
{
//    self.contentWrapper.center = leftCenter;
}

- (void)disableMenu
{
//    [self.contentWrapper removeGestureRecognizer:self.contentPanRecognizer];
}

- (void)enableMenu
{
//    [self.contentWrapper addGestureRecognizer:self.contentPanRecognizer];
}

#pragma mark - gesture handler methods
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer
{
    UIView *contentWrapper = recognizer.view;
    CGPoint translation = [recognizer translationInView:self.view];
    CGFloat stopPositionX = contentWrapper.center.x + translation.x;
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    
    if (stopPositionX < leftCenter.x) {
        return;
    }
    
    contentWrapper.center = CGPointMake(stopPositionX, leftCenter.y);
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint endCenter;
        UIView *view = [contentWrapper.subviews lastObject];
        
        if (stopPositionX > leftCenter.x + MINTRANSLATION) {
            endCenter = rightCenter;
            view.userInteractionEnabled = NO;
            [contentWrapper addGestureRecognizer:contentTapRecognizer];
        } else {
            endCenter = leftCenter;
            view.userInteractionEnabled = YES;
            [contentWrapper removeGestureRecognizer:contentTapRecognizer];
        }
        
        [UIView animateWithDuration:0.75
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^(void) {
                             contentWrapper.center = endCenter;
                         }
                         completion:nil];
    }
}

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer
{
    UIView *contentWrapper = [self.view viewWithTag:101];
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^(void){
                         contentWrapper.center = leftCenter;
                     }
                     completion:nil];
    
    UIView *view = [contentWrapper.subviews lastObject];
    view.userInteractionEnabled = YES;
    [recognizer.view removeGestureRecognizer:contentTapRecognizer];
}

#pragma mark - segue methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//    if ([segue.identifier isEqualToString:@"segueToContent"]) {
//        self.contentController = segue.destinationViewController;
//    } else if ([segue.identifier isEqualToString:@"segueToIndex"]) {
//        self.indexController = segue.destinationViewController;
//    }
}

@end


























