//
//  BUCFrontPageViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCFrontPageViewController.h"
#import "BUCDataManager.h"
#import "BUCContentViewController.h"
#import "BUCPost.h"
#import "BUCListContainerView.h"

@interface BUCFrontPageViewController ()

@property (nonatomic, weak) BUCContentViewController *contentVC;

@end

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
    
    self.contentVC = (BUCContentViewController *)self.parentViewController.parentViewController;
    [self.contentVC displayLoading];
    
    BUCFrontPageViewController * __weak weakSelf = self;
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
    [dataManager
     getFrontListOnSuccess:
     ^(NSArray *list)
     {
         [weakSelf buildList:list];
         [weakSelf.contentVC hideLoading];
     }
     onFail:^(NSError *error)		
     {
                                    
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
- (void)buildList:(NSArray *)list
{
    UIScrollView *view = (UIScrollView *)self.view;
    view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    CGFloat posY = 10.0f;
    CGRect frame = CGRectInset(view.bounds, 10.0f, 10.0f);
    CGFloat width = frame.size.width;
    BUCListContainerView *container = nil;
        
    for (BUCPost *post in list) {
        container = [[BUCListContainerView alloc] init];
        container.layer.borderWidth = 0.3f;
        container.layer.borderColor = [UIColor lightGrayColor].CGColor;
        container.backgroundColor = [UIColor whiteColor];
        container.layer.cornerRadius = 3.0f;
        //[container addTarget:self action:@selector(shit:) forControlEvents:UIControlEventTouchUpInside];
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(5.0f, 5.0f, width - 10.0f, 0.0f)];
        title.numberOfLines = 0;
        title.attributedText = post.title;
        [title sizeToFit];
        container.frame = CGRectMake(10.0f, posY, width, title.frame.size.height + 30.0f);
        [container addSubview:title];
        posY = posY + container.frame.size.height + 5.0f;
        [view addSubview:container];
    }
    
    view.contentSize = CGSizeMake(view.bounds.size.width, posY);
}
@end




