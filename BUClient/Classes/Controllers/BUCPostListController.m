//
//  BUCFrontPageViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCPostListController.h"
#import "BUCDataManager.h"
#import "BUCContentController.h"
#import "BUCPost.h"
#import "BUCListItemView.h"

@interface BUCPostListController () <UIScrollViewDelegate>

@property (nonatomic, weak) BUCContentController *contentVC;

@end

@implementation BUCPostListController
#pragma mark - setup
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.contentVC = (BUCContentController *)self.parentViewController.parentViewController;
    
    UIScrollView *context = (UIScrollView *)self.view;
    context.delegate = self;
    context.contentInset = UIEdgeInsetsZero;
    
    CGFloat contextWidth = context.bounds.size.width;
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat refreshIndicatorHeight = statusBarHeight + navigationBarHeight;
    UIView *refreshIndicator = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contextWidth, refreshIndicatorHeight)];
    refreshIndicator.hidden = YES;
    refreshIndicator.tag = 100;
    UILabel *refreshPrompt = [self labelFromText:[[NSAttributedString alloc] initWithString:@"pull to refresh"] origin:CGPointZero];
    refreshPrompt.center = refreshIndicator.center;
    [refreshIndicator addSubview:refreshPrompt];
    [context addSubview:refreshIndicator];
    
    [self.contentVC displayLoading];
    [self loadList];
}

- (void)viewWillAppear:(BOOL)animated
{

}

#pragma mark - IBAction and unwind methods
- (IBAction)refresh:(id)sender
{
    [self displayLoading];    
    [self loadList];
}

- (void)loadList
{
    BUCPostListController * __weak weakSelf = self;
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
    [dataManager
     getFrontListOnSuccess:
     ^(NSArray *list)
     {
         [[weakSelf.view viewWithTag:101] removeFromSuperview];
         [weakSelf buildList:list];
         [weakSelf hideLoading];
     }
     onFail:^(NSError *error)
     {
         [weakSelf hideLoading];
         [weakSelf.contentVC alertMessage:error.localizedDescription];
     }];
}

- (IBAction)jumpToForum:(id)sender
{

}

- (IBAction)jumpToPost:(id)sender
{
    BUCListItemView *item = (BUCListItemView *)sender;
    NSLog(@"%ld", item.tag);
}

- (IBAction)unwindToFront:(UIStoryboardSegue *)segue
{

}

- (IBAction)jumpToPoster:(id)sender
{
    
}

#pragma mark - scroll view delegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    CGFloat refreshFireHeight = 50.0f;
    if (scrollView.contentOffset.y <= -refreshFireHeight)
    {
        [self displayLoading];
        [self loadList];
    }
}

#pragma mark - private methods
- (void)buildList:(NSArray *)list
{
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
    
    // set up wrapper
    UIView *wrapper = [[UIView alloc] init];
    wrapper.tag = 101; // use this tag to get wrapper view before refresh happened
    wrapper.opaque = YES;
    
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
        BUCListItemView *listItem = [[BUCListItemView alloc] initWithFrame:CGRectZero];
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
        UIButton *poster = [self buttonFromTitle:post.user origin:CGPointMake(listItemChildOriginX, listItemChildOriginY)];
        [listItem addSubview:poster];
        listItemChildOriginX = listItemChildOriginX + poster.frame.size.width + listItemChildGapX;
        
        // connecting text
        UILabel *text = [self labelFromText:[[NSAttributedString alloc]
                                             initWithString:@"发表于"
                                             attributes:captionAttrs]
                            origin:CGPointMake(listItemChildOriginX, listItemChildOriginY)];
        [listItem addSubview:text];
        listItemChildOriginX = listItemChildOriginX + text.frame.size.width + listItemChildGapX;
        
        // forum name
        UIButton *fname = [self buttonFromTitle:post.fname origin:CGPointMake(listItemChildOriginX, listItemChildOriginY)];
        [listItem addSubview:fname];
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
        UIButton *lastReplyWho = [self buttonFromTitle:post.lastReply.user origin:CGPointMake(listItemChildOriginX, listItemChildOriginY)];
        [listItem addSubview:lastReplyWho];
        listItemChildOriginY = listItemChildOriginY + lastReplyWho.frame.size.height + listItemChildGapY;
        
        // set up post container's frame and add it to the wrapper
        listItem.frame = CGRectMake(listItemOriginX, listItemOriginY, wrapperWidth, listItemChildOriginY);
        [wrapper addSubview:listItem];
        
        // accumulatation
        wrapperHeight = wrapperHeight + listItemChildOriginY + listItemBottomMargin;
        listItemOriginY = wrapperHeight;
    }
    
    wrapperHeight = wrapperHeight - listItemBottomMargin;
    UIView *refreshIndicator = [self.view viewWithTag:100];
    CGFloat refreshIndicatorHeight = refreshIndicator.frame.size.height;
    wrapper.frame = CGRectMake(wrapperMarginX, wrapperMarginY + refreshIndicatorHeight, wrapperWidth, wrapperHeight);
    ((UIScrollView *)self.view).contentSize = CGSizeMake(wrapperWidth + 2 * wrapperMarginX, wrapperHeight + 2 * wrapperMarginY + refreshIndicatorHeight);
    [self.view addSubview:wrapper];
}

- (UIButton *)buttonFromTitle:(NSAttributedString *)title origin:(CGPoint)origin
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setAttributedTitle:title forState:UIControlStateNormal];
    button.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 1.0f, 0.0f, 1.0f);
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
    [self.contentVC displayLoading];
}

- (void)hideLoading
{
    [self.contentVC hideLoading];
    UIScrollView *scrollView = (UIScrollView *)self.view;
    UIView *refreshIndicator = [scrollView viewWithTag:100];
    refreshIndicator.hidden = NO;
}
@end




