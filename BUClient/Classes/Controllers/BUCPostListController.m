#import "BUCPostListController.h"
#import "BUCPostDetailController.h"
#import "BUCConstants.h"
#import "BUCListItem.h"
#import "BUCTextButton.h"
#import "BUCDataManager.h"
#import "BUCModels.h"


@interface BUCPostListController () <UIScrollViewDelegate>


@property (nonatomic, weak) UIView *listWrapper;

@property (nonatomic) NSArray *postList;


@end


@implementation BUCPostListController


#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIScrollView *context = (UIScrollView *)self.view;
    context.delegate = self;

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
    
    [dataManager
     getFrontListOnSuccess:^(NSArray *list) {
         weakSelf.postList = list;
         [weakSelf buildList:list];
         [weakSelf hideLoading];
     }
     onError:^(NSError *error) {
         [weakSelf hideLoading];
         [weakSelf alertMessage:error.localizedDescription];
     }];
}


- (IBAction)jumpToPost:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:BUCMainStoryboardPath bundle:nil];
    BUCPostDetailController *postDetailController = [storyboard instantiateViewControllerWithIdentifier:BUCPostDetailControllerStoryboardID];
    BUCListItem *listItem = (BUCListItem *)sender;
    BUCPost *post = [self.postList objectAtIndex:listItem.tag];
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        listItem.backgroundColor = [UIColor whiteColor];
    }];
    
    postDetailController.postID = post.pid;
    [(UINavigationController *)self.parentViewController pushViewController:postDetailController animated:YES];
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
    CGFloat leftPadding = 5.0f;
    CGFloat topPadding = 5.0f;
    CGFloat rightPadding = 5.0f;
    CGFloat bottomPadding = 5.0f;
    
    UIScrollView *context = (UIScrollView *)self.view;

    // set up wrapper
    UIView *wrapper = [[UIView alloc] init];
    
    CGFloat listItemBottomMargin = 5.0f;
    
    CGFloat contextWidth = CGRectGetWidth(context.frame);
    CGFloat wrapperWidth = contextWidth - leftPadding - rightPadding;
    
    // index of list item
    NSInteger index = 0;
    
    // layout position in wrapper's coordinate
    CGFloat layoutPointY = 0;
    
    for (BUCPost *post in list) {
        BUCListItem *listItem = [self listItemOfPost:post frame:CGRectMake(0, layoutPointY, wrapperWidth, 0)];
        listItem.tag = index;
        index = index + 1;
        [listItem addTarget:self action:@selector(jumpToPost:) forControlEvents:UIControlEventTouchUpInside];
        [wrapper addSubview:listItem];
        layoutPointY = layoutPointY + CGRectGetHeight(listItem.frame) + listItemBottomMargin;
    }

    CGFloat topBarHeight = 64.0f;
    wrapper.frame = CGRectMake(leftPadding, topPadding + topBarHeight, wrapperWidth, layoutPointY - listItemBottomMargin);

    context.contentSize = CGSizeMake(contextWidth, layoutPointY + topBarHeight + bottomPadding);

    if (self.listWrapper) {
        [self.listWrapper removeFromSuperview];
    }
    
    [context addSubview:wrapper];
    self.listWrapper = wrapper;
}


- (BUCListItem *)listItemOfPost:(BUCPost *)post frame:(CGRect)aRect {
    CGFloat leftPadding = 5.0f;
    CGFloat topPadding = 5.0f;
    CGFloat rightPadding = 5.0f;
    CGFloat bottomPadding = 5.0f;
    
    CGFloat x = CGRectGetMinX(aRect);
    CGFloat y = CGRectGetMinY(aRect);
    CGFloat contextWidth = CGRectGetWidth(aRect);
    
    CGFloat contentWidth = contextWidth - leftPadding - rightPadding;
    
    CGFloat titleBottomMargin = 20.0f;
    
    CGFloat metaRightMargin = 2.0f;
    CGFloat metaBottomMargin = 5.0f;
    
    CGFloat separatorHeight = 0.5f;
    
    CGFloat layoutPointX = leftPadding;
    CGFloat layoutPointY = topPadding;
    
    BUCListItem *listItem = [[BUCListItem alloc] initWithFrame:CGRectZero];
    
    // title
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 0.0f)];
    title.numberOfLines = 0;
    title.attributedText = post.title;
    [title sizeToFit];
    [listItem addSubview:title];
    layoutPointY = layoutPointY + CGRectGetHeight(title.frame) + titleBottomMargin;
    
    // username of original poster
    BUCTextButton *poster = [[BUCTextButton alloc] init];
    [poster setTitle:post.user];
    poster.frame = CGRectOffset(poster.frame, layoutPointX, layoutPointY);
    [listItem addSubview:poster];
    [poster addTarget:self action:@selector(jumpToPoster:) forControlEvents:UIControlEventTouchUpInside];
    layoutPointX = layoutPointX + CGRectGetWidth(poster.frame) + metaRightMargin;
    
    // forum name
    NSDictionary *metaAttributes = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]};
    NSAttributedString *snippetRichText = [[NSAttributedString alloc] initWithString:@"发表于" attributes:metaAttributes];
    UILabel *snippet = [self labelFromRichText:snippetRichText];
    snippet.frame = CGRectOffset(snippet.frame, layoutPointX, layoutPointY);
    [listItem addSubview:snippet];
    layoutPointX = layoutPointX + CGRectGetWidth(snippet.frame) + metaRightMargin;
    
    BUCTextButton *forumName = [[BUCTextButton alloc] init];
    [forumName setTitle:post.fname];
    forumName.frame = CGRectOffset(forumName.frame, layoutPointX, layoutPointY);
    [listItem addSubview:forumName];
    layoutPointX = layoutPointX + CGRectGetWidth(forumName.frame) + metaRightMargin;
    
    // reply count
    NSString *replyCountString = [NSString stringWithFormat:@"%@人回复", post.childCount];
    NSAttributedString *replyCountRichText = [[NSAttributedString alloc] initWithString:replyCountString attributes:metaAttributes];
    UILabel *replyCount = [self labelFromRichText:replyCountRichText];
    replyCount.frame = CGRectOffset(replyCount.frame, layoutPointX, layoutPointY);
    [listItem addSubview:replyCount];
    layoutPointX = leftPadding;
    layoutPointY = layoutPointY + CGRectGetHeight(replyCount.frame) + metaBottomMargin;
    
    // separator
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, contentWidth, separatorHeight)];
    separator.backgroundColor = [UIColor lightGrayColor];
    [listItem addSubview:separator];
    layoutPointY = layoutPointY + separatorHeight + metaBottomMargin;
    
    // last reply
    NSString *lastReplyString = [NSString stringWithFormat:@"最后回复：%@ by", post.lastReply.dateline];
    NSAttributedString *lastReplyRichText = [[NSAttributedString alloc] initWithString:lastReplyString attributes:metaAttributes];
    UILabel *lastReply = [self labelFromRichText:lastReplyRichText];
    lastReply.frame = CGRectOffset(lastReply.frame, layoutPointX, layoutPointY);
    [listItem addSubview:lastReply];
    layoutPointX = layoutPointX + CGRectGetWidth(lastReply.frame) + metaRightMargin;
    
    BUCTextButton *lastReplyPoster = [[BUCTextButton alloc] init];
    [lastReplyPoster setTitle:post.lastReply.user];
    lastReplyPoster.frame = CGRectOffset(lastReplyPoster.frame, layoutPointX, layoutPointY);
    [listItem addSubview:lastReplyPoster];
    
    layoutPointY = layoutPointY + CGRectGetHeight(lastReplyPoster.frame) + bottomPadding;
    
    // reset frame
    listItem.frame = CGRectMake(x, y, contextWidth, layoutPointY);

    return listItem;
}


- (UILabel *)labelFromRichText:(NSAttributedString *)richText {
    UILabel *snippet = [[UILabel alloc] init];
    snippet.attributedText = richText;
    [snippet sizeToFit];
    
    return snippet;
}


@end

















