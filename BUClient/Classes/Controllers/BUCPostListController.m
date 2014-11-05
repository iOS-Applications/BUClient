#import "BUCPostListController.h"
#import "BUCContentController.h"
#import "BUCPostDetailController.h"
#import "BUCConstants.h"
#import "BUCListItem.h"
#import "BUCTextButton.h"
#import "BUCDataManager.h"
#import "BUCPost.h"


@interface BUCPostListController () <UIScrollViewDelegate>


@property (nonatomic, weak) BUCContentController *contentController;

@property (nonatomic, weak) UIView *listWrapper;

@property (nonatomic) NSArray *postList;


@end


@implementation BUCPostListController


#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIScrollView *context = (UIScrollView *)self.view;
    context.delegate = self;

    self.contentController = (BUCContentController *)self.parentViewController;

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [self refresh:nil];
}


#pragma mark - IBAction and unwind methods
- (IBAction)refresh:(id)sender {
    [self displayLoading];    
    [self loadList];
}


- (void)loadList {
    BUCPostListController * __weak weakSelf = self;
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
    UIView *listWrapper = self.listWrapper;
    BUCContentController *contentController = self.contentController;
    
    [dataManager
     getFrontListOnSuccess:^(NSArray *list) {
         weakSelf.postList = list;
         [listWrapper removeFromSuperview];
         [weakSelf buildList:list];
         [weakSelf hideLoading];
     }
     onError:^(NSError *error) {
         [weakSelf hideLoading];
         [contentController alertMessage:error.localizedDescription];
     }];
}


- (IBAction)jumpToPost:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:BUCMainStoryboardPath bundle:nil];
    BUCPostDetailController *postDetailController = [storyboard instantiateViewControllerWithIdentifier:BUCPostDetailControllerStoryboardID];
    BUCListItem *listItem = (BUCListItem *)sender;
    NSArray *postList = self.postList;
    BUCPost *post = [postList objectAtIndex:listItem.tag];
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        listItem.backgroundColor = [UIColor whiteColor];
    }];
    
    postDetailController.postID = post.pid;
    [self.contentController pushViewController:postDetailController animated:YES];
}


- (IBAction)jumpToForum:(id)sender {
    BUCTextButton *button = (BUCTextButton *)sender;
    [UIView animateWithDuration:0.3 animations:^(void) {
        button.alpha = 1.0f;
    }];
}

- (IBAction)jumpToPoster:(id)sender {
    BUCTextButton *button = (BUCTextButton *)sender;
    [UIView animateWithDuration:0.3 animations:^(void) {
        button.alpha = 1.0f;
    }];
}


#pragma mark - scroll view delegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat refreshFireHeight = 40.0f;
    if (scrollView.contentOffset.y <= -refreshFireHeight) {
        [self displayLoading];
        [self loadList];
    }
}

#pragma mark - private methods
- (void)buildList:(NSArray *)list {
    UIScrollView *context = (UIScrollView *)self.view;

    // set up wrapper
    UIView *wrapper = [[UIView alloc] init];
    wrapper.opaque = YES;
    
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
    
    for (BUCPost *post in list) {
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

    CGFloat topBarHeight = 64.0f;
    wrapper.frame = CGRectMake(wrapperMarginX, wrapperMarginY + topBarHeight, wrapperWidth, wrapperHeight);
    context.contentSize = CGSizeMake(wrapperWidth + 2 * wrapperMarginX, wrapperHeight + 2 * wrapperMarginY + topBarHeight);
    
    if (self.listWrapper) {
        [self.listWrapper removeFromSuperview];
    }
    
    [context addSubview:wrapper];
    self.listWrapper = wrapper;
}


- (BUCTextButton *)buttonFromTitle:(NSAttributedString *)title origin:(CGPoint)origin {
    BUCTextButton *button = [[BUCTextButton alloc] init];
    [button setTitle:title];
    [button sizeToFit];
    button.frame = CGRectOffset(button.frame, origin.x, origin.y);
    
    return button;
}


- (UILabel *)labelFromText:(NSAttributedString *)text origin:(CGPoint)origin {
    UILabel *label = [[UILabel alloc] init];
    label.attributedText = text;
    [label sizeToFit];
    label.frame = CGRectOffset(label.frame, origin.x, origin.y);
    
    return label;
}


- (void)displayLoading {
    [self.contentController displayLoading];
    self.view.userInteractionEnabled = NO;
}


- (void)hideLoading {
    [self.contentController hideLoading];
    self.view.userInteractionEnabled = YES;
}


@end

















