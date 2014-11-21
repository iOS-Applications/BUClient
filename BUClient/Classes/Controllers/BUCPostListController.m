#import "BUCPostListController.h"
#import "BUCPostDetailController.h"
#import "BUCConstants.h"
#import "BUCListItem.h"
#import "BUCTextButton.h"
#import "BUCDataManager.h"
#import "BUCModels.h"


@interface BUCPostListController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet BUCListItem *previousHolder;
@property (weak, nonatomic) IBOutlet UILabel *previous;
@property (weak, nonatomic) IBOutlet BUCListItem *nextHolder;
@property (weak, nonatomic) IBOutlet UILabel *moreOrNext;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *moreIndicator;

@property (nonatomic, weak) UIView *listWrapper;

@property (nonatomic) NSMutableArray *postList;
@property (nonatomic) NSMutableArray *backUp;

@property (nonatomic) NSString *from;
@property (nonatomic) NSString *to;

@property (nonatomic) NSUInteger postCount;
@property (nonatomic) NSUInteger location;
@property (nonatomic) NSUInteger length;

@end


@implementation BUCPostListController


#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIScrollView *context = (UIScrollView *)self.view;
    context.delegate = self;
    context.scrollIndicatorInsets = UIEdgeInsetsMake(64.0f, 0, 0, 0);

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.previousHolder.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 40.0f);
    self.previousHolder.frame = CGRectInset(self.previousHolder.frame, BUCDefaultPadding, 0);
    [self.previousHolder addTarget:self action:@selector(loadPrevious) forControlEvents:UIControlEventTouchUpInside];
    self.previous.frame = CGRectOffset(self.previous.frame, -BUCDefaultPadding, 0);
    self.moreOrNext.frame = CGRectOffset(self.moreOrNext.frame, -BUCDefaultPadding, 0);
    self.nextHolder.frame = self.previousHolder.frame;
    self.previousHolder.frame = CGRectOffset(self.previousHolder.frame, 0, 64.0f + BUCDefaultPadding);
    
    if (self.fname) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@[1]", self.fname];
        self.from = @"0";
        self.to = @"20";
        self.location = 0;
        self.length = 0;
    } else {
        self.navigationItem.title = @"最新主题";
    }
    
    [self refresh];
}


#pragma mark - actions and unwind methods
- (void)refresh {
    [(UIScrollView *)self.view setContentOffset:CGPointMake(0, 0) animated:NO];
    [self displayLoading];
    self.backUp = self.postList;
    self.postList = nil;
    self.view.userInteractionEnabled = NO;
    if (self.fid) {
        BUCPostListController * __weak weakSelf = self;
        [[BUCDataManager sharedInstance]
         getPostCountOfForum:self.fid
         post:nil
         onSuccess:^(NSUInteger count) {
             weakSelf.postCount = count;
             [weakSelf loadList];
         } onError:^(NSError *error) {
             [weakSelf hideLoading];
             [weakSelf alertMessage:error.localizedDescription];
         }];
        
    } else {
        [self loadList];
    }
}


- (void)loadList {
    BUCPostListController * __weak weakSelf = self;
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
    
    void (^listBlock)(NSArray *) = ^(NSArray *list) {
        if (weakSelf.fid) {
            NSUInteger location = weakSelf.location;
            NSUInteger from = weakSelf.from.integerValue;
            if (abs((int)(location - from)) == 40) {
                weakSelf.location = from;
                weakSelf.length = 20;
            } else{
                weakSelf.length = weakSelf.length + 20;
            }
        }
        weakSelf.view.userInteractionEnabled = YES;
        weakSelf.backUp = nil;
        [weakSelf buildList:list];
        [weakSelf hideLoading];
        [weakSelf.moreIndicator stopAnimating];
    };
    
    void (^errorBlock)(NSError *) = ^(NSError *error) {
        weakSelf.view.userInteractionEnabled = YES;
        weakSelf.postList = weakSelf.backUp;
        [weakSelf hideLoading];
        [weakSelf.moreIndicator stopAnimating];
        [weakSelf alertMessage:error.localizedDescription];
    };

    if (self.fid) {
        [dataManager getForumList:self.fid from:self.from to:self.to onSuccess:listBlock onError:errorBlock];
    } else {
        [dataManager getFrontListOnSuccess:listBlock onError:errorBlock];
    }
}


- (void)jumpToPost:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:BUCMainStoryboardPath bundle:nil];
    BUCPostDetailController *postDetailController = [storyboard instantiateViewControllerWithIdentifier:BUCPostDetailControllerStoryboardID];
    BUCListItem *listItem = (BUCListItem *)sender;
    BUCPost *post = [self.postList objectAtIndex:listItem.tag];
    postDetailController.post = post;
    [(UINavigationController *)self.parentViewController pushViewController:postDetailController animated:YES];
}


- (void)jumpToForum:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:BUCMainStoryboardPath bundle:nil];
    BUCPostListController *postListController = [storyboard instantiateViewControllerWithIdentifier:BUCPostListControllerStoryboardID];
    BUCTextButton *forumName = (BUCTextButton *)sender;
    BUCListItem *listItem = (BUCListItem *)forumName.superview;
    BUCPost *post = [self.postList objectAtIndex:listItem.tag];
    postListController.fid = post.fid;
    postListController.fname = post.fname.string;
    [(UINavigationController *)self.parentViewController pushViewController:postListController animated:YES];
}


- (void)jumpToPoster:(id)sender {

}


- (void)loadPrevious {
    self.from = [NSString stringWithFormat:@"%ld", self.location - 40];
    self.to = [NSString stringWithFormat:@"%ld", self.location - 20];
    [self refresh];
}


- (void)loadNext {
    self.from = [NSString stringWithFormat:@"%ld", self.location + 40];
    self.to = [NSString stringWithFormat:@"%ld", self.location + 60];
    [self refresh];
}


- (void)loadMore {
    self.from = [NSString stringWithFormat:@"%ld", self.location + 20];
    self.to = [NSString stringWithFormat:@"%ld", self.location + 40];
    [self.moreIndicator startAnimating];
    [self loadList];
}


#pragma mark - scroll view delegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat refreshFireHeight = 40.0f;
    if (scrollView.contentOffset.y <= -refreshFireHeight) {
        [self refresh];
    } else if (self.fid && self.postList.count < 40 && self.postCount >= self.location + 20) {
        CGFloat loadMoreHeight = ceilf(CGRectGetHeight(self.listWrapper.frame) / 2);
        if (scrollView.contentOffset.y >= loadMoreHeight) {
            [self loadMore];
        }
    }
}


#pragma mark - private methods
- (void)buildList:(NSArray *)list {
    UIScrollView *context = (UIScrollView *)self.view;
    UIView *wrapper;
    CGFloat layoutPointY;
    
    CGFloat contextWidth = CGRectGetWidth(context.frame);
    CGFloat wrapperWidth = contextWidth - 2 * BUCDefaultPadding;
    CGFloat topBarHeight = 64.0f;
    
    // index of list item
    NSInteger index = self.postList.count;

    // set up wrapper
    CGFloat contextLayoutPointY = topBarHeight + BUCDefaultPadding;
    if (index == 0) {
        self.previousHolder.hidden = YES;
        [self.listWrapper removeFromSuperview];
        wrapper = [[UIView alloc] init];
        wrapper.backgroundColor = context.backgroundColor;
        self.listWrapper = wrapper;
        layoutPointY = 0;
        self.postList = [[NSMutableArray alloc] init];
    } else {
        wrapper = self.listWrapper;
        layoutPointY = CGRectGetHeight(wrapper.frame) + BUCDefaultMargin;
    }
    
    if (self.location >= 40) {
        self.previousHolder.hidden = NO;
        contextLayoutPointY = contextLayoutPointY + CGRectGetHeight(self.previousHolder.frame) + BUCDefaultPadding;
    } else {
        self.previousHolder.hidden = YES;
    }
    
    if (self.fid) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@[%ld]", self.fname, self.location / 40 + 1];
    }
    
    for (BUCPost *post in list) {
        if ([self isLoadedBefore:post]) {
            continue;
        }
        
        BUCListItem *listItem = [self listItemOfPost:post frame:CGRectMake(0, layoutPointY, wrapperWidth, 0)];
        listItem.tag = index;
        index = index + 1;
        [listItem addTarget:self action:@selector(jumpToPost:) forControlEvents:UIControlEventTouchUpInside];
        [wrapper addSubview:listItem];
        layoutPointY = layoutPointY + CGRectGetHeight(listItem.frame) + BUCDefaultMargin;
        
        [self.postList addObject:post];
    }

    wrapper.frame = CGRectMake(BUCDefaultPadding, contextLayoutPointY, wrapperWidth, layoutPointY - BUCDefaultMargin);
    
    contextLayoutPointY = contextLayoutPointY + layoutPointY;
    
    if (self.postCount > 0 && self.postCount >= self.location + self.length) {
        self.nextHolder.hidden = NO;
        self.nextHolder.frame = CGRectMake(BUCDefaultPadding, contextLayoutPointY, CGRectGetWidth(self.nextHolder.frame), CGRectGetHeight(self.nextHolder.frame));
        contextLayoutPointY = contextLayoutPointY + CGRectGetHeight(self.nextHolder.frame) + BUCDefaultMargin;
        if (self.length == 20) {
            self.moreOrNext.text = @"More...";
            [self.nextHolder removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [self.nextHolder addTarget:self action:@selector(loadMore) forControlEvents:UIControlEventTouchUpInside];
        } else if (self.length == 40) {
            self.moreOrNext.text = @"下一页";
            [self.nextHolder removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [self.nextHolder addTarget:self action:@selector(loadNext) forControlEvents:UIControlEventTouchUpInside];
        }
    } else {
        self.nextHolder.hidden = YES;
    }
    
    if (contextLayoutPointY < CGRectGetHeight(context.frame)) {
        contextLayoutPointY = CGRectGetHeight(context.frame) + 1.0f;
    }
    
    context.contentSize = CGSizeMake(contextWidth, contextLayoutPointY);
    [context addSubview:wrapper];
}


- (BUCListItem *)listItemOfPost:(BUCPost *)post frame:(CGRect)aRect {
    CGFloat x = CGRectGetMinX(aRect);
    CGFloat y = CGRectGetMinY(aRect);
    CGFloat contextWidth = CGRectGetWidth(aRect);
    
    CGFloat contentWidth = contextWidth - 2 * BUCDefaultPadding;
    
    CGFloat titleBottomMargin = 20.0f;
    
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
    layoutPointX = layoutPointX + CGRectGetWidth(poster.frame) + BUCDefaultMargin;
    
    NSDictionary *metaAttributes = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]};
    
    NSAttributedString *snippetRichText = [[NSAttributedString alloc] initWithString:@"发表于" attributes:metaAttributes];
    UILabel *snippet = [self labelWithRichText:snippetRichText frame:CGRectMake(layoutPointX, layoutPointY, 0, 0)];
    [listItem addSubview:snippet];
    layoutPointX = layoutPointX + CGRectGetWidth(snippet.frame) + BUCDefaultMargin;
    
    // forum name
    if (!self.fid) {    
        BUCTextButton *forumName = [[BUCTextButton alloc] initWithTitle:post.fname location:CGPointMake(layoutPointX, layoutPointY)];
        [listItem addSubview:forumName];
        [forumName addTarget:self action:@selector(jumpToForum:) forControlEvents:UIControlEventTouchUpInside];
        layoutPointX = layoutPointX + CGRectGetWidth(forumName.frame) + BUCDefaultMargin;
    } else {
        UILabel *dateline = [self labelWithRichText:post.dateline frame:CGRectMake(layoutPointX, layoutPointY, 0, 0)];
        [listItem addSubview:dateline];
        layoutPointX = layoutPointX + CGRectGetWidth(dateline.frame) + BUCDefaultMargin;
    }
    
    // reply count
    NSString *childCountString = [NSString stringWithFormat:@"• %@人回复", post.childCount];
    NSAttributedString *replyCountRichText = [[NSAttributedString alloc] initWithString:childCountString attributes:metaAttributes];
    UILabel *childCount = [self labelWithRichText:replyCountRichText frame:CGRectMake(layoutPointX, layoutPointY, 0, 0)];
    [listItem addSubview:childCount];
    
    // view count
    if (self.fid) {
        layoutPointX = layoutPointX + CGRectGetWidth(childCount.frame) + BUCDefaultMargin;
        NSString *viewCountString = [NSString stringWithFormat:@"• %@次点击", post.viewCount];
        NSAttributedString *viewCountRichText = [[NSAttributedString alloc] initWithString:viewCountString attributes:metaAttributes];
        UILabel *viewCount = [self labelWithRichText:viewCountRichText frame:CGRectMake(layoutPointX, layoutPointY, 0, 0)];
        [listItem addSubview:viewCount];
    }
    
    layoutPointX = BUCDefaultPadding;
    layoutPointY = layoutPointY + CGRectGetHeight(childCount.frame) + BUCDefaultMargin;
    
    // separator
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, contentWidth, BUCBorderWidth)];
    separator.backgroundColor = [UIColor lightGrayColor];
    [listItem addSubview:separator];
    layoutPointY = layoutPointY + BUCBorderWidth + BUCDefaultMargin;
    
    // last reply
    NSString *lastReplyString = [NSString stringWithFormat:@"最后回复：%@ by", post.lastPostDateline.string];
    NSAttributedString *lastReplyRichText = [[NSAttributedString alloc] initWithString:lastReplyString attributes:metaAttributes];
    UILabel *lastReply = [self labelWithRichText:lastReplyRichText frame:CGRectMake(layoutPointX, layoutPointY, 0, 0)];
    [listItem addSubview:lastReply];
    layoutPointX = layoutPointX + CGRectGetWidth(lastReply.frame) + BUCDefaultMargin;
    
    BUCTextButton *lastReplyPoster = [[BUCTextButton alloc] initWithTitle:post.lastPoster location:CGPointMake(layoutPointX, layoutPointY)];
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


- (BOOL)isLoadedBefore:(BUCPost *)newpost {
    for (BUCPost *post in self.postList) {
        if ([post.pid isEqualToString:newpost.pid]) {
            return YES;
        }
    }
    
    return NO;
}


@end

















