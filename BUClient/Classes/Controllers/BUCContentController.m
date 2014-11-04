//
//  BUCContentController.m
//  BUClient
//
//  Created by Joe Jeong on 1/22/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCContentController.h"
#import "BUCConstants.h"

@interface BUCContentController ()


@property (nonatomic, strong) IBOutlet UIView *loadingView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;


@end


@implementation BUCContentController


#pragma mark - overrided methods
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set up loading view
    self.loadingView.center = self.view.center;
    self.loadingView.layer.cornerRadius = 10.0f;
    [self.view addSubview:self.loadingView];
}


#pragma mark - public methods
- (void)displayLoading {
    [self.activityIndicator startAnimating];
    self.loadingView.hidden = NO;
}


- (void)hideLoading {
    [self.activityIndicator stopAnimating];
    self.loadingView.hidden = YES;
}


- (void)alertMessage:(NSString *)message {
    [[[UIAlertView alloc]
      initWithTitle:nil
      message:message
      delegate:self
      cancelButtonTitle:@"OK"
      otherButtonTitles:nil] show];
}


@end
























