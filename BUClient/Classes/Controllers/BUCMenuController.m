//
//  BUCMenuController.m
//  BUClient
//
//  Created by Joe Jeong on 11/4/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCMenuController.h"
#import "BUCContentController.h"
#import "BUCPostListController.h"
#import "BUCConstants.h"

@interface BUCMenuController ()

@end

@implementation BUCMenuController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (IBAction)shit:(id)sender {
    BUCContentController *f = (BUCContentController *)self.parentViewController;
    BUCPostListController *s = nil;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:BUCMainStoryboardPath bundle:nil];
    s = [storyboard instantiateViewControllerWithIdentifier:BUCPostListControllerStoryboardID];
    [f pushViewController:s animated:YES];
}

@end
