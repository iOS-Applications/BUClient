//
//  BUCRootViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/12/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCRootController.h"
#import "BUCLoginController.h"
#import "BUCContentController.h"
#import "BUCAuthManager.h"

@interface BUCRootController ()
// global constants
@property (nonatomic) CGFloat MINTRANSLATION;
@property (nonatomic) CGFloat MAXTRANSLATION;
@property (nonatomic) CGPoint RIGHTCENTER;
@property (nonatomic) CGPoint LEFTCENTER;
@property (nonatomic) CGPoint FARRIGHTCENTER;

// properties to keep references of objects frequently used
@property (nonatomic) IBOutlet UIPanGestureRecognizer *CONTENTPANRECOGNIZER;
@property (nonatomic) IBOutlet UITapGestureRecognizer *CONTENTTAPRECOGNIZER;
@property (nonatomic, weak) IBOutlet UIView *CONTENTWRAPPER;

@property (nonatomic, weak) BUCContentController *CONTENTCONTROLLER;

@end

@implementation BUCRootController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set up global constants
    self.MINTRANSLATION = 130.0f;
    self.MAXTRANSLATION = 250.0f;
    self.LEFTCENTER = self.view.center;
    self.RIGHTCENTER = CGPointMake(self.LEFTCENTER.x + self.MAXTRANSLATION, self.LEFTCENTER.y);
    self.FARRIGHTCENTER = CGPointMake(self.LEFTCENTER.x + self.view.frame.size.width, self.LEFTCENTER.y);

    // set up appearance of content wrapper
    UIView *contentWrapper = self.CONTENTWRAPPER;
    contentWrapper.layer.shadowOpacity = 1.0;
    contentWrapper.layer.shadowRadius = 5.0;
    contentWrapper.layer.shadowPath = [UIBezierPath bezierPathWithRect:contentWrapper.bounds].CGPath;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // check if app is just launched
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isJustLaunched"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isJustLaunched"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // check if user is logged in last time
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"])
        {
            // if yes, load content directly
            [self loadContent];
        }
        else
        {
            // otherwise, bring up the login form
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            BUCLoginController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"loginController"];
            
            [self presentViewController:loginVC animated:NO completion:nil];
        }
    }
}

#pragma mark - public methods
- (void)showMenu
{
    UIView *contentWrapper = self.CONTENTWRAPPER;
    UITapGestureRecognizer *contentRecognizer = self.CONTENTTAPRECOGNIZER;
    CGPoint rightCenter = self.RIGHTCENTER;
    UIView *contentView = self.CONTENTCONTROLLER.view;
    
    [UIView animateWithDuration:0.75
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^(void) {
                         contentWrapper.center = rightCenter;
                     }
                     completion:nil];
    
    contentView.userInteractionEnabled = NO;
    [contentWrapper addGestureRecognizer:contentRecognizer];
}

- (void)switchContentWith:(NSString *)segueIdendifier completion:(void (^)(void))completeHandler
{
//    UIView *contentWrapper = [self.view viewWithTag:101];
//    [UIView animateWithDuration:0.25
//                          delay:0
//                        options:UIViewAnimationOptionCurveEaseInOut
//                     animations:^{
//                         contentWrapper.center = FARRIGHTCENTER;
//                     }
//                     completion:^(BOOL finished) {
//                         [UIView animateWithDuration:0.5
//                                               delay:0.05
//                                             options:UIViewAnimationOptionCurveEaseInOut
//                                          animations:^{
//                                              contentWrapper.center = LEFTCENTER;
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
//    [contentWrapper removeGestureRecognizer:self.contentTapRecognizer];
}

#pragma mark - gesture handler methods
- (IBAction)handleContentPan:(UIPanGestureRecognizer *)recognizer
{
    UIView *context = self.view;
    UIView *contentWrapper = recognizer.view;
    CGPoint leftCenter = self.LEFTCENTER;
    CGPoint rightCenter = self.RIGHTCENTER;
    UITapGestureRecognizer *contentTapRecognizer = self.CONTENTTAPRECOGNIZER;
    CGFloat minTranslation = self.MINTRANSLATION;
    UIView *contentView = self.CONTENTCONTROLLER.view;
    
    CGPoint endCenter;
    CGPoint translation = [recognizer translationInView:context];
    CGFloat stopPositionX = contentWrapper.center.x + translation.x;
    [recognizer setTranslation:CGPointMake(0, 0) inView:context];
    
    if (stopPositionX < leftCenter.x)
    {
        return;
    }
    
    contentWrapper.center = CGPointMake(stopPositionX, leftCenter.y);
    
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        if (stopPositionX > leftCenter.x + minTranslation)
        {
            endCenter = rightCenter;
            contentView.userInteractionEnabled = NO;
            [contentWrapper addGestureRecognizer:contentTapRecognizer];
        }
        else
        {
            endCenter = leftCenter;
            contentView.userInteractionEnabled = YES;
            [contentWrapper removeGestureRecognizer:contentTapRecognizer];
        }
        
        [UIView
         animateWithDuration:0.75
         delay:0
         options:UIViewAnimationOptionCurveEaseInOut
         animations:
         ^(void)
         {
             contentWrapper.center = endCenter;
         }
         completion:nil];
    }
}

- (IBAction)handleContentTap:(UITapGestureRecognizer *)recognizer
{
    UIView *contentWrapper = self.CONTENTWRAPPER;
    CGPoint leftCenter = self.LEFTCENTER;
    UITapGestureRecognizer *contentTapRecognizer = self.CONTENTTAPRECOGNIZER;
    
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

#pragma mark - unwind callback
- (IBAction)unwindToRoot:(UIStoryboardSegue *)segue
{
    [self loadContent];
}

#pragma mark - private methods
- (void)loadContent
{
    UIView *contentWrapper = self.CONTENTWRAPPER;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    BUCContentController *contentController = [storyboard instantiateViewControllerWithIdentifier:@"contentController"];

    contentController.view.frame = contentWrapper.frame;
    [self addChildViewController:contentController];
    [contentWrapper addSubview:contentController.view];
    [contentController didMoveToParentViewController:self];
    
    self.CONTENTCONTROLLER = contentController;
    self.view.userInteractionEnabled = YES;
}
@end


























