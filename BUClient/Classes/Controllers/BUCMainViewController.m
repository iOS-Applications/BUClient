//
//  BUCMainViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/12/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCMainViewController.h"

#define MINTRANSLATION 130.0
#define MAXTRANSLATION 250.0

@interface BUCMainViewController ()
{
    CGPoint rightCenter;
    CGPoint leftCenter;
}

@property (weak, nonatomic) IBOutlet UIView *index;
@property (weak, nonatomic) IBOutlet UIView *content;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *contentTapRecognizer;

@end

@implementation BUCMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    leftCenter = self.view.center;
    rightCenter = CGPointMake(leftCenter.x + MAXTRANSLATION, leftCenter.y);
    
    self.content.layer.shadowOpacity = 1.0;
    self.content.layer.shadowRadius = 5.0;
    self.content.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.content.bounds].CGPath;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showIndex
{
    [UIView animateWithDuration:0.75
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^(void) {
                         self.content.center = rightCenter;
                     }
                     completion:nil];
    
    UIView *view = [self.content.subviews lastObject];
    view.userInteractionEnabled = NO;
    [self.content addGestureRecognizer:self.contentTapRecognizer];
}

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
                              delay:0.0
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
                          delay:0.01
                        options:UIViewAnimationOptionTransitionCurlUp
                     animations:^(void){
                         recognizer.view.center = leftCenter;
                        }
                     completion:nil];
    
    UIView *view = [recognizer.view.subviews lastObject];
    view.userInteractionEnabled = YES;
    [recognizer.view removeGestureRecognizer:self.contentTapRecognizer];
}
@end


























