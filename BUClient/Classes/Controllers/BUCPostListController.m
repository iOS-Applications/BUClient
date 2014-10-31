//
//  BUCFrontPageViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCPostListController.h"
#import "BUCRootController.h"
#import "BUCContentController.h"
#import "BUCPostDetailController.h"
#import "BUCListItem.h"
#import "BUCTextButton.h"
#import "BUCDataManager.h"
#import "BUCPost.h"


@interface BUCPostListController () <UIScrollViewDelegate>

@property (nonatomic, weak) BUCContentController *CONTENTCONTROLLER;
@property (nonatomic, weak) BUCRootController *ROOTCONTROLLER;
@property (nonatomic, weak) UINavigationController *NAVCONTROLLER;

@property (nonatomic, weak) UIView *REFRESHINDICATOR;
@property (nonatomic, weak) UIView *LISTWRAPPER;

@property (nonatomic) NSArray *POSTLIST;

@end

@implementation BUCPostListController
#pragma mark - setup
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIScrollView *context = (UIScrollView *)self.view;
    context.delegate = self;
    context.contentInset = UIEdgeInsetsZero;
    
    CGFloat contextWidth = context.bounds.size.width;
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat refreshIndicatorHeight = statusBarHeight + navigationBarHeight;
    UIView *refreshIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contextWidth, refreshIndicatorHeight)];
    UILabel *refreshPrompt = [self labelFromText:[[NSAttributedString alloc] initWithString:@"pull to refresh"] origin:CGPointZero];
    refreshPrompt.center = refreshIndicator.center;
    refreshPrompt.frame = CGRectOffset(refreshPrompt.frame, 0.0f, 10.0f);
    [refreshIndicator addSubview:refreshPrompt];
    [context addSubview:refreshIndicator];
    
    self.REFRESHINDICATOR = refreshIndicator;
    self.NAVCONTROLLER = (UINavigationController *)self.parentViewController;
    self.CONTENTCONTROLLER = (BUCContentController *)self.NAVCONTROLLER.parentViewController;
    self.ROOTCONTROLLER = (BUCRootController *)self.CONTENTCONTROLLER.parentViewController;
    
    [self refresh:nil];
}

#pragma mark - IBAction and unwind methods
- (IBAction)refresh:(id)sender
{
    [self displayLoading];    
    [self loadList];
}

- (IBAction)showMenu:(id)sender
{
    [self.ROOTCONTROLLER showMenu];
}

- (void)loadList
{
    BUCPostListController * __weak weakSelf = self;
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
    UIView *listWrapper = self.LISTWRAPPER;
    BUCContentController *contentController = self.CONTENTCONTROLLER;
    
    [dataManager
     getFrontListOnSuccess:
     ^(NSArray *list)
     {
         weakSelf.POSTLIST = list;
         [listWrapper removeFromSuperview];
         [weakSelf buildList:list];
         [weakSelf hideLoading];
     }
     onError:^(NSError *error)
     {
         [weakSelf hideLoading];
         [contentController alertMessage:error.localizedDescription];
     }];
}

- (IBAction)jumpToPost:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navController = self.NAVCONTROLLER;
    BUCPostDetailController *postDetailController = [storyboard instantiateViewControllerWithIdentifier:@"postDetailController"];
    BUCListItem *listItem = (BUCListItem *)sender;
    NSArray *postList = self.POSTLIST;
    BUCPost *post = [postList objectAtIndex:listItem.tag];
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        listItem.backgroundColor = [UIColor whiteColor];
    }];
    
    postDetailController.postID = post.pid;
    [navController pushViewController:postDetailController animated:YES];
}

- (IBAction)jumpToForum:(id)sender
{
    BUCTextButton *button = (BUCTextButton *)sender;
    [UIView animateWithDuration:0.3 animations:^(void) {
        button.alpha = 1.0f;
    }];
}

- (IBAction)jumpToPoster:(id)sender
{
    BUCTextButton *button = (BUCTextButton *)sender;
    [UIView animateWithDuration:0.3 animations:^(void) {
        button.alpha = 1.0f;
    }];
}

- (IBAction)unwindToPostList:(UIStoryboardSegue *)segue
{

}

#pragma mark - scroll view delegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    CGFloat refreshFireHeight = 40.0f;
    if (scrollView.contentOffset.y <= -refreshFireHeight)
    {
        [self displayLoading];
        [self loadList];
    }
}

#pragma mark - private methods
- (void)buildList:(NSArray *)list
{
    // outside objects
    UIView *refreshIndicator = self.REFRESHINDICATOR;
    UIScrollView *context = (UIScrollView *)self.view;

    // set up wrapper
    UIView *wrapper = [[UIView alloc] init];
    wrapper.opaque = YES;
    self.LISTWRAPPER = wrapper;
    
    
    // set up basic geometry
    CGFloat wrapperMarginX = 5.0f;
    CGFloat wrapperMarginY = 5.0f;
    
    CGFloat listItemBottomMargin = 5.0f;
    
    CGFloat listItemPaddingX = 5.0f;
    CGFloat listItemPaddingY = 5.0f;
    
    CGFloat listItemChildGapX = 2.0f;
    CGFloat listItemChildGapY = 5.0f;
    
    CGFloat wrapperWidth = self.view.bounds.size.width - 2 * wrapperMarginX;
    CGFloat contentWidth = wrapperWidth - 2 * listItemPaddingX;
    
    CGFloat listItemChildSeparatorHeight = 0.6f;
    
    
    // accumulation variables
    NSInteger index = 0; // index of list item
    CGFloat wrapperHeight = 0.0f;
    
    // layout position in wrapper's coordinate
    CGFloat listItemOriginX = 0.0f;
    CGFloat listItemOriginY = 0.0f;
    
    // attributes of attributed string
    NSDictionary *captionAttrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]};
    
    for (BUCPost *post in list)
    {
        // set up initial layout position in list item's coordinate
        CGFloat listItemChildOriginX = listItemPaddingX;
        CGFloat listItemChildOriginY = listItemPaddingY;
        
        // set up post list item
        BUCListItem *listItem = [[BUCListItem alloc] initWithFrame:CGRectZero];
        listItem.tag = index++; // use tag to identify post tapped later
        [listItem addTarget:self action:@selector(jumpToPost:) forControlEvents:UIControlEventTouchUpInside];
        
        // title
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(listItemChildOriginX, listItemChildOriginY, contentWidth, 0.0f)];
        title.numberOfLines = 0;
        title.attributedText = post.title;
        [title sizeToFit];
        [listItem addSubview:title];
        listItemChildOriginY = listItemChildOriginY + title.frame.size.height;
        
        // set gap between title and other items to 20 points
        listItemChildOriginY = listItemChildOriginY + 20.0f;
        
        // username of original poster
        BUCTextButton *poster = [self buttonFromTitle:post.user origin:CGPointMake(listItemChildOriginX, listItemChildOriginY)];
        [listItem addSubview:poster];
        [poster addTarget:self action:@selector(jumpToPoster:) forControlEvents:UIControlEventTouchUpInside];
        listItemChildOriginX = listItemChildOriginX + poster.frame.size.width + listItemChildGapX;
        
        // connecting text
        UILabel *text = [self labelFromText:[[NSAttributedString alloc]
                                             initWithString:@"发表于"
                                             attributes:captionAttrs]
                            origin:CGPointMake(listItemChildOriginX, listItemChildOriginY)];
        [listItem addSubview:text];
        listItemChildOriginX = listItemChildOriginX + text.frame.size.width + listItemChildGapX;
        
        // forum name
        BUCTextButton *fname = [self buttonFromTitle:post.fname origin:CGPointMake(listItemChildOriginX, listItemChildOriginY)];
        [listItem addSubview:fname];
        [fname addTarget:self action:@selector(jumpToForum:) forControlEvents:UIControlEventTouchUpInside];
        listItemChildOriginX = listItemChildOriginX + fname.frame.size.width + listItemChildGapX;

        // reply count
        UILabel *replyCount = [self labelFromText:[[NSAttributedString alloc]
                                                   initWithString:[NSString stringWithFormat:@"%@人回复", post.childCount]
                                                   attributes:captionAttrs]
                                           origin:CGPointMake(listItemChildOriginX, listItemChildOriginY)];
        [listItem addSubview:replyCount];
        
        listItemChildOriginY = listItemChildOriginY + replyCount.frame.size.height + listItemChildGapY;
        
        // add a separator
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(listItemPaddingX, listItemChildOriginY, contentWidth, listItemChildSeparatorHeight)];
        separator.backgroundColor = [UIColor lightGrayColor];
        [listItem addSubview:separator];

        listItemChildOriginX = listItemPaddingX;
        listItemChildOriginY = listItemChildOriginY + listItemChildSeparatorHeight + listItemChildGapY;
        
        // last reply dateline
        UILabel *lastReplyWhen = [self labelFromText:[[NSAttributedString alloc]
                                                      initWithString:[NSString stringWithFormat:@"最后回复：%@ by", post.lastReply.dateline]
                                                      attributes:captionAttrs]
                                              origin:CGPointMake(listItemChildOriginX, listItemChildOriginY)];
        [listItem addSubview:lastReplyWhen];
        listItemChildOriginX = listItemChildOriginX + lastReplyWhen.frame.size.width + listItemChildGapX;
        
        // last reply author
        BUCTextButton *lastReplyWho = [self buttonFromTitle:post.lastReply.user origin:CGPointMake(listItemChildOriginX, listItemChildOriginY)];
        [listItem addSubview:lastReplyWho];
        [lastReplyWho addTarget:self action:@selector(jumpToPoster:) forControlEvents:UIControlEventTouchUpInside];
        listItemChildOriginY = listItemChildOriginY + lastReplyWho.frame.size.height + listItemChildGapY;
        
        // set up post container's frame and add it to the wrapper
        listItem.frame = CGRectMake(listItemOriginX, listItemOriginY, wrapperWidth, listItemChildOriginY);
        [wrapper addSubview:listItem];
        
        // accumulatation
        wrapperHeight = wrapperHeight + listItemChildOriginY + listItemBottomMargin;
        listItemOriginY = wrapperHeight;
    }
    
    wrapperHeight = wrapperHeight - listItemBottomMargin;

    CGFloat refreshIndicatorHeight = refreshIndicator.frame.size.height;
    wrapper.frame = CGRectMake(wrapperMarginX, wrapperMarginY + refreshIndicatorHeight, wrapperWidth, wrapperHeight);
    context.contentSize = CGSizeMake(wrapperWidth + 2 * wrapperMarginX, wrapperHeight + 2 * wrapperMarginY + refreshIndicatorHeight);
    [context addSubview:wrapper];
}

- (BUCTextButton *)buttonFromTitle:(NSAttributedString *)title origin:(CGPoint)origin
{
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
//    [button setAttributedTitle:title forState:UIControlStateNormal];
//    button.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 1.0f, 0.0f, 1.0f);
//    [button sizeToFit];
//    button.frame = CGRectOffset(button.frame, origin.x, origin.y);
//    [button setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    
    BUCTextButton *button = [[BUCTextButton alloc] init];
    [button setTitle:title];
    [button sizeToFit];
    button.frame = CGRectOffset(button.frame, origin.x, origin.y);
    
    return button;
}

- (UILabel *)labelFromText:(NSAttributedString *)text origin:(CGPoint)origin
{
    UILabel *label = [[UILabel alloc] init];
    label.attributedText = text;
    [label sizeToFit];
    label.frame = CGRectOffset(label.frame, origin.x, origin.y);
    
    return label;
}

- (void)displayLoading
{
    [self.CONTENTCONTROLLER displayLoading];
    self.view.userInteractionEnabled = NO;
}

- (void)hideLoading
{
    [self.CONTENTCONTROLLER hideLoading];
    self.view.userInteractionEnabled = YES;
}

@end




