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
    postDetailController.post = post;
    [(UINavigationController *)self.parentViewController pushViewController:postDetailController animated:YES];
}


- (IBAction)jumpToForum:(id)sender {
    
}

- (IBAction)jumpToPoster:(id)sender {

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
    
    CGFloat contextWidth = CGRectGetWidth(context.frame);
    CGFloat wrapperWidth = contextWidth - 2 * BUCDefaultPadding;
    
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
        layoutPointY = layoutPointY + CGRectGetHeight(listItem.frame) + BUCDefaultMargin;
    }

    CGFloat topBarHeight = 64.0f;
    wrapper.frame = CGRectMake(BUCDefaultPadding, BUCDefaultPadding + topBarHeight, wrapperWidth, layoutPointY - BUCDefaultMargin);

    context.contentSize = CGSizeMake(contextWidth, layoutPointY + topBarHeight + BUCDefaultPadding);

    if (self.listWrapper) {
        [self.listWrapper removeFromSuperview];
    }
    
    [context addSubview:wrapper];
    self.listWrapper = wrapper;
}


- (BUCListItem *)listItemOfPost:(BUCPost *)post frame:(CGRect)aRect {
    CGFloat x = CGRectGetMinX(aRect);
    CGFloat y = CGRectGetMinY(aRect);
    CGFloat contextWidth = CGRectGetWidth(aRect);
    
    CGFloat contentWidth = contextWidth - 2 * BUCDefaultPadding;
    
    CGFloat titleBottomMargin = 20.0f;
    
    CGFloat metaRightMargin = 2.0f;
    
    CGFloat layoutPointX = BUCDefaultPadding;
    CGFloat layoutPointY = BUCDefaultPadding;
    
    BUCListItem *listItem = [[BUCListItem alloc] initWithFrame:CGRectZero];
    
    // title
    UILabel *title = [self labelWithRichText:post.title frame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 0)];
    [listItem addSubview:title];
    layoutPointY = layoutPointY + CGRectGetHeight(title.frame) + titleBottomMargin;
    
    // username of original poster
    BUCTextButton *poster = [[BUCTextButton alloc] initWithTitle:post.user location:CGPointMake(layoutPointX, layoutPointY)];
    [listItem addSubview:poster];
    [poster addTarget:self action:@selector(jumpToPoster:) forControlEvents:UIControlEventTouchUpInside];
    layoutPointX = layoutPointX + CGRectGetWidth(poster.frame) + metaRightMargin;
    
    // forum name
    NSDictionary *metaAttributes = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]};
    NSAttributedString *snippetRichText = [[NSAttributedString alloc] initWithString:@"发表于" attributes:metaAttributes];
    UILabel *snippet = [self labelWithRichText:snippetRichText frame:CGRectMake(layoutPointX, layoutPointY, 0, 0)];
    [listItem addSubview:snippet];
    layoutPointX = layoutPointX + CGRectGetWidth(snippet.frame) + metaRightMargin;
    
    BUCTextButton *forumName = [[BUCTextButton alloc] initWithTitle:post.fname location:CGPointMake(layoutPointX, layoutPointY)];
    [listItem addSubview:forumName];
    layoutPointX = layoutPointX + CGRectGetWidth(forumName.frame) + metaRightMargin;
    
    // reply count
    NSString *replyCountString = [NSString stringWithFormat:@"%@人回复", post.childCount];
    NSAttributedString *replyCountRichText = [[NSAttributedString alloc] initWithString:replyCountString attributes:metaAttributes];
    UILabel *replyCount = [self labelWithRichText:replyCountRichText frame:CGRectMake(layoutPointX, layoutPointY, 0, 0)];
    [listItem addSubview:replyCount];
    layoutPointX = BUCDefaultPadding;
    layoutPointY = layoutPointY + CGRectGetHeight(replyCount.frame) + BUCDefaultMargin;
    
    // separator
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, contentWidth, BUCBorderWidth)];
    separator.backgroundColor = [UIColor lightGrayColor];
    [listItem addSubview:separator];
    layoutPointY = layoutPointY + BUCBorderWidth + BUCDefaultMargin;
    
    // last reply
    NSString *lastReplyString = [NSString stringWithFormat:@"最后回复：%@ by", post.lastReply.dateline.string];
    NSAttributedString *lastReplyRichText = [[NSAttributedString alloc] initWithString:lastReplyString attributes:metaAttributes];
    UILabel *lastReply = [self labelWithRichText:lastReplyRichText frame:CGRectMake(layoutPointX, layoutPointY, 0, 0)];
    [listItem addSubview:lastReply];
    layoutPointX = layoutPointX + CGRectGetWidth(lastReply.frame) + metaRightMargin;
    
    BUCTextButton *lastReplyPoster = [[BUCTextButton alloc] initWithTitle:post.lastReply.user location:CGPointMake(layoutPointX, layoutPointY)];
    [listItem addSubview:lastReplyPoster];
    
    layoutPointY = layoutPointY + CGRectGetHeight(lastReplyPoster.frame) + BUCDefaultPadding;
    
    // reset frame
    listItem.frame = CGRectMake(x, y, contextWidth, layoutPointY);

    return listItem;
}


- (UILabel *)labelWithRichText:(NSAttributedString *)richText frame:(CGRect)frame {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.numberOfLines = 0;
    label.attributedText = richText;
    [label sizeToFit];
    
    return label;
}


@end

















