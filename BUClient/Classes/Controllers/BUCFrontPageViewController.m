//
//  BUCFrontPageViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCFrontPageViewController.h"
#import "BUCDataManager.h"

@implementation BUCFrontPageViewController
#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {

    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    static NSString *kUserLoginNotification = @"kUserLoginNotification";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getData) name:kUserLoginNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)getData
{
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
    [dataManager getFrontListOnSuccess:^(NSArray *list) {
        
    }
                                onFail:^(NSError *error) {
                                    
                                }];
}

#pragma mark - IBAction and unwind methods
- (IBAction)jumpToPoster:(id)sender forEvent:(UIEvent *)event {
    
}

- (IBAction)jumpToForum:(id)sender forEvent:(UIEvent *)event {

}

- (IBAction)jumpToThread:(id)sender forEvent:(UIEvent *)event {

}

- (IBAction)unwindToFront:(UIStoryboardSegue *)segue
{
    
}

#pragma mark - private methods

@end





