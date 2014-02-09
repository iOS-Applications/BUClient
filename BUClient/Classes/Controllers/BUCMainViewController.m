//
//  BUCMainViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/12/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCMainViewController.h"
#import "BUCLoginViewController.h"

#define MINTRANSLATION 130.0
#define MAXTRANSLATION 250.0

@interface BUCMainViewController ()
{
    CGPoint rightCenter;
    CGPoint leftCenter;
    CGPoint farRightCenter;
}

@property (weak, nonatomic) IBOutlet UIView *index;
@property (weak, nonatomic) IBOutlet UIView *content;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *contentTapRecognizer;

@end

@implementation BUCMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    leftCenter = self.view.center;
    rightCenter = CGPointMake(leftCenter.x + MAXTRANSLATION, leftCenter.y);
    farRightCenter = CGPointMake(leftCenter.x + 320, leftCenter.y);
    
    self.content.layer.shadowOpacity = 1.0;
    self.content.layer.shadowRadius = 5.0;
    self.content.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.content.bounds].CGPath;    
}

#pragma mark - public methods
- (void)displayLoginWithMessage:(NSString *)message
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    BUCLoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];
    [self presentViewController:loginVC animated:NO completion:nil];
    if ([message length]) [loginVC alertWithMessage:message];
}

- (void)revealIndex
{
    [UIView animateWithDuration:0.75
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^(void) {
                         self.content.center = rightCenter;
                     }
                     completion:nil];
    
    UIView *view = [self.content.subviews lastObject];
    view.userInteractionEnabled = NO;
    [self.content addGestureRecognizer:self.contentTapRecognizer];
}

- (void)switchContentWith:(NSString *)segueIdendifier
{
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.content.center = farRightCenter;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.5
                                               delay:0.05
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              self.content.center = leftCenter;
                                          }
                                          completion:nil];
                         
                         [self.contentController performSegueWithIdentifier:segueIdendifier sender:nil];
                     }];
    
    UIView *view = [self.content.subviews lastObject];
    view.userInteractionEnabled = YES;
    [self.content removeGestureRecognizer:self.contentTapRecognizer];
}

#pragma mark - gesture handler methods
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.view];
    CGFloat stopPositionX = recognizer.view.center.x + translation.x;
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    
    if (stopPositionX < leftCenter.x) {
        return;
    }

    recognizer.view.center = CGPointMake(stopPositionX, leftCenter.y);
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint endCenter;
        UIView *view = [recognizer.view.subviews lastObject];
        
        if (stopPositionX > leftCenter.x + MINTRANSLATION) {
            endCenter = rightCenter;
            view.userInteractionEnabled = NO;
            [recognizer.view addGestureRecognizer:self.contentTapRecognizer];
        } else {
            endCenter = leftCenter;
            view.userInteractionEnabled = YES;
            [recognizer.view removeGestureRecognizer:self.contentTapRecognizer];
        }
        
        [UIView animateWithDuration:0.75
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^(void) {
                             recognizer.view.center = endCenter;
                         }
                         completion:nil];
    }
}

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer
{
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^(void){
                         recognizer.view.center = leftCenter;
                        }
                     completion:nil];
    
    UIView *view = [recognizer.view.subviews lastObject];
    view.userInteractionEnabled = YES;
    [recognizer.view removeGestureRecognizer:self.contentTapRecognizer];
}

#pragma mark - segue methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segueToContent"]) {
        self.contentController = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"segueToIndex"]) {
        self.indexController = segue.destinationViewController;
    }
}
@end


























