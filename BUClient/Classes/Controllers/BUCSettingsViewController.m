//
//  BUCSettingsViewController.m
//  BUClient
//
//  Created by Joe Jeong on 2/10/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCSettingsViewController.h"
#import "BUCMainViewController.h"
#import "BUCAppDelegate.h"
#import "BUCUserListViewController.h"
#import "BUCUser.h"

@interface BUCSettingsViewController ()
//@property (weak, nonatomic) IBOutlet UIWebView *imageContainer;
@property BUCMainViewController *mainController;
@property BUCUser *user;

@property (weak, nonatomic) IBOutlet UISwitch *loadImage;
@property (weak, nonatomic) IBOutlet UILabel *currentUser;
@end

@implementation BUCSettingsViewController
#pragma mark - overrided methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    BUCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    self.mainController = appDelegate.mainViewController;
    self.user = [BUCUser sharedInstance];
    
    self.currentUser.text = self.user.username;
    
    NSString *loadImage = self.user.loadImage;
    if ([loadImage isEqualToString:@"yes"]) {
        self.loadImage.on = YES;
    } else {
        self.loadImage.on = NO;
    }
    
//    NSString *path = [[NSBundle mainBundle] bundlePath];
//    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
//    [self.imageContainer loadHTMLString:@"<img width='42px' height='63px' src='avatar.png'>" baseURL:baseURL];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.mainController disableIndex];
}

#pragma mark - unwind methods and actions
- (IBAction)unwindToSettings:(UIStoryboardSegue *)segue
{
    self.currentUser.text = self.user.username;
    [self.mainController enableIndex];
}

- (IBAction)toggleImageLoad:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (self.loadImage.on) {
        self.user.loadImage = @"yes";
        [defaults setObject:@"yes" forKey:@"loadImage"];
    } else {
        self.user.loadImage = @"no";
        [defaults setObject:@"no" forKey:@"loadImage"];
    }
    
    [defaults synchronize];
}

#pragma mark - private methods
- (IBAction)displayIndex:(id)sender {
    [self.mainController revealIndex];
}

@end
