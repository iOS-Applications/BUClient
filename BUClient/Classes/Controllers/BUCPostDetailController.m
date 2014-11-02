//
//  BUCPostDetailController.m
//  BUClient
//
//  Created by Joe Jeong on 10/31/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCPostDetailController.h"
#import "BUCRootController.h"
#import "BUCContentController.h"
#import "BUCDataManager.h"
#import "BUCPost.h"
#import "BUCPostFragment.h"

@interface BUCPostDetailController () <UIScrollViewDelegate>

@property (nonatomic, weak) BUCContentController *CONTENTCONTROLLER;
@property (nonatomic, weak) BUCRootController *ROOTCONTROLLER;
@property (nonatomic, weak) UINavigationController *NAVCONTROLLER;

@property (nonatomic, weak) UIView *REFRESHINDICATOR;
@property (nonatomic, weak) UIView *LISTWRAPPER;

@property (nonatomic) NSArray *POSTLIST;

@end

@implementation BUCPostDetailController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIScrollView *context = (UIScrollView *)self.view;
    context.delegate = self;
    context.contentInset = UIEdgeInsetsZero;
    
    self.NAVCONTROLLER = (UINavigationController *)self.parentViewController;
    self.CONTENTCONTROLLER = (BUCContentController *)self.NAVCONTROLLER.parentViewController;
    self.ROOTCONTROLLER = (BUCRootController *)self.CONTENTCONTROLLER.parentViewController;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self refresh:nil];
}

- (IBAction)refresh:(id)sender
{
    [self displayLoading];
    [self loadList];
}

#pragma mark - private methods
- (void)loadList
{
    BUCPostDetailController * __weak weakSelf = self;
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
//    UIView *listWrapper = self.LISTWRAPPER;
    BUCContentController *contentController = self.CONTENTCONTROLLER;
    self.postID = @"10581123";
    
    [dataManager
     getPost:self.postID
     
     from:@"0"
     
     to:@"20"
     
     onSuccess:
     ^(NSArray *list)
     {
         weakSelf.POSTLIST = list;
//         [listWrapper removeFromSuperview];
         [weakSelf buildList:list];
         [weakSelf hideLoading];
     }
     
     onError:^(NSError *error)
     {
         [weakSelf hideLoading];
         [contentController alertMessage:error.localizedDescription];
     }];
}

- (void)buildList:(NSArray *)list
{    
//    for (BUCPost *post in list)
//    {
//        NSMutableString *s = [[NSMutableString alloc] init];
//        for (BUCPostFragment *fragment in post.content)
//        {
//            
//        }
//    }
}

- (void)displayLoading
{
    
}

- (void)hideLoading
{
    
}
@end
