#import "BUCPostListController.h"
#import "BUCPostDetailController.h"
#import "BUCConstants.h"
#import "BUCPostListCell.h"
#import "BUCDataManager.h"
#import "BUCModels.h"

static CGFloat const BUCPostListSupplementaryViewHeight = 40.0f;
static NSUInteger const BUCPostListMinPostCount = 20;
static NSUInteger const BUCPostListMaxPostCount = 40;

static NSString * const BUCCellNib = @"BUCPostListCell";

@interface BUCPostListController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *listTopToHeader;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *listBottomToFooter;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *listWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *listHeight;

@property (weak, nonatomic) IBOutlet BUCPostListCell *previousHolder;
@property (weak, nonatomic) IBOutlet BUCPostListCell *nextHolder;
@property (weak, nonatomic) IBOutlet UILabel *moreOrNext;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *moreIndicator;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *listWrapper;

@property (nonatomic) NSMutableArray *postList;
@property (nonatomic) NSMutableArray *cellList;

@property (nonatomic) NSString *from;
@property (nonatomic) NSString *to;

@property (nonatomic) NSUInteger postCount;
@property (nonatomic) NSUInteger location;
@property (nonatomic) NSUInteger length;

@property (nonatomic) BOOL isRefresh;
@property (nonatomic) BOOL isLoading;

@end


@implementation BUCPostListController


#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cellList = [[NSMutableArray alloc] init];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    self.listWidth.constant = CGRectGetWidth(self.view.frame) - 2 * BUCDefaultPadding;
    
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


#pragma mark - actions
- (void)refresh {
    [self displayLoading];

    self.isRefresh = YES;
    if (self.fid) {
        BUCPostListController * __weak weakSelf = self;
        [[BUCDataManager sharedInstance]
         childCountOfForum:self.fid
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
            NSUInteger from = weakSelf.from.integerValue;
            if (weakSelf.isRefresh) {
                weakSelf.location = from;
                weakSelf.length = BUCPostListMinPostCount;
            } else {
                weakSelf.length = weakSelf.length + BUCPostListMinPostCount;
            }
        }
        
        [weakSelf buildList:list];
        [weakSelf hideLoading];
        [weakSelf.moreIndicator stopAnimating];
    };
    
    void (^errorBlock)(NSError *) = ^(NSError *error) {
        [weakSelf hideLoading];
        [weakSelf.moreIndicator stopAnimating];
        [weakSelf alertMessage:error.localizedDescription];
    };

    if (self.fid) {
        [dataManager listOfForum:self.fid from:self.from to:self.to onSuccess:listBlock onError:errorBlock];
    } else {
        [dataManager listOfFrontOnSuccess:listBlock onError:errorBlock];
    }
}


- (void)jumpToPost:(id)sender {
    BUCPostDetailController *postDetailController = [self.storyboard instantiateViewControllerWithIdentifier:BUCPostDetailControllerStoryboardID];
    BUCPostListCell *cell = (BUCPostListCell *)sender;
    postDetailController.post = [self.postList objectAtIndex:cell.tag];
    [(UINavigationController *)self.parentViewController pushViewController:postDetailController animated:YES];
}


- (void)jumpToForum:(id)sender {
    BUCPostListController *postListController = [self.storyboard instantiateViewControllerWithIdentifier:BUCPostListControllerStoryboardID];
    UIButton *forumName = (UIButton *)sender;
    BUCPostListCell *listItem = (BUCPostListCell *)forumName.superview;
    BUCPost *post = [self.postList objectAtIndex:listItem.tag];
    postListController.fid = post.fid;
    postListController.fname = post.fname;
    [(UINavigationController *)self.parentViewController pushViewController:postListController animated:YES];
}


- (void)jumpToPoster:(id)sender {

}


- (IBAction)loadPrevious {
    self.from = [NSString stringWithFormat:@"%lu", (unsigned long)(self.location - BUCPostListMaxPostCount)];
    self.to = [NSString stringWithFormat:@"%lu", (unsigned long)(self.location - BUCPostListMaxPostCount + BUCPostListMinPostCount)];
    [self refresh];
}

- (IBAction)loadMoreOrNext {
    unsigned long from = 0;

    if (self.length < BUCPostListMaxPostCount) {
        [self loadMore];
        return;
    } else {
        from = self.location + BUCPostListMaxPostCount;
    }
    
    unsigned long to = from + BUCPostListMinPostCount;
    self.from = [NSString stringWithFormat:@"%lu", from];
    self.to = [NSString stringWithFormat:@"%lu", to];
    [self refresh];
}

- (void)loadMore {
    unsigned long from = self.location + self.length;
    unsigned long to = from + BUCPostListMinPostCount;
    self.from = [NSString stringWithFormat:@"%lu", from];
    self.to = [NSString stringWithFormat:@"%lu", to];
    
    [self.moreIndicator startAnimating];
    self.isLoading = YES;
    [self loadList];
}


#pragma mark - scroll view delegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.isLoading || self.isRefresh || decelerate) {
        return;
    }
    
    CGFloat refreshFireHeight = 40.0f;
    if (scrollView.contentOffset.y <= -refreshFireHeight) {
        [self refresh];
    } else if (self.fid && self.length != BUCPostListMaxPostCount && self.postCount >= self.location + self.length) {
        CGFloat loadMoreHeight = ceilf(CGRectGetHeight(self.listWrapper.frame) / 2);
        if (scrollView.contentOffset.y >= loadMoreHeight) {
            [self loadMore];
        }
    }
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.isLoading || self.isRefresh) {
        return;
    }
    
    if (self.fid && self.length != BUCPostListMaxPostCount && self.postCount >= self.location + self.length) {
        CGFloat loadMoreHeight = ceilf(CGRectGetHeight(self.listWrapper.frame) / 2);
        if (scrollView.contentOffset.y >= loadMoreHeight) {
            [self loadMore];
        }
    }
}


#pragma mark - private methods
- (void)buildList:(NSArray *)list {
    // header
    if (self.location >= BUCPostListMaxPostCount) {
        self.previousHolder.hidden = NO;
        self.listTopToHeader.constant = BUCDefaultMargin;
    } else {
        self.previousHolder.hidden = YES;
        self.listTopToHeader.constant = -BUCPostListSupplementaryViewHeight;
    }
    
    CGFloat listHeight = 0.0f;
    CGFloat listWidth = self.listWidth.constant;
    // list content
    NSMutableArray *postList;
    if (self.isRefresh) {
        postList = [[NSMutableArray alloc] init];
        self.isRefresh = NO;
        [self.scrollView setContentOffset:CGPointZero];
    } else {
        self.isLoading = NO;
        postList = self.postList;
        listHeight = CGRectGetHeight(self.listWrapper.frame) + BUCDefaultMargin;
    }

    NSInteger index = postList.count;
    NSInteger cellCount = self.cellList.count;

    for (BUCPost *post in list) {
        if ([self isLoadedBefore:post against:postList]) {
            continue;
        }
        
        BUCPostListCell *cell;
        if (index >= cellCount) {
            cell = [[[NSBundle mainBundle] loadNibNamed:BUCCellNib owner:nil options:nil] lastObject];
            [self.cellList addObject:cell];
            [self.listWrapper addSubview:cell];
        } else {
            cell = [self.cellList objectAtIndex:index];
        }
        
        cell.frame = CGRectMake(0, listHeight, listWidth, 0);
        cell.tag = index;
        cell.hidden = NO;
        [self configureCell:cell post:post];
        
        [postList addObject:post];
        index = index + 1;
        listHeight = listHeight + CGRectGetHeight(cell.frame) + BUCDefaultMargin;
    }
    
    for (; index < cellCount; index = index + 1) {
        BUCPostListCell *cell = [self.cellList objectAtIndex:index];
        cell.hidden = YES;
    }
    
    self.postList = postList;
    self.listHeight.constant = listHeight - BUCDefaultMargin;
    
    // footer
    if (self.postCount > 0 && self.postCount >= self.location + self.length) {
        self.nextHolder.hidden = NO;
        self.listBottomToFooter.constant = BUCDefaultMargin;
        
        if (self.length < BUCPostListMaxPostCount) {
            self.moreOrNext.text = @"More...";
        } else {
            self.moreOrNext.text = @"下一页";
        }
    } else {
        self.nextHolder.hidden = YES;
        self.listBottomToFooter.constant = -BUCPostListSupplementaryViewHeight;
    }
    
    // update title of top bar
    if (self.fid) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@[%lu]", self.fname, (unsigned long)(self.location / BUCPostListMaxPostCount + 1)];
    }
}


- (void)configureCell:(BUCPostListCell *)cell post:(BUCPost *)post {
    // title
    cell.title.preferredMaxLayoutWidth = self.listWidth.constant - 2 * BUCDefaultMargin;
    cell.title.attributedText = post.title;
    
    // username
    [cell.username setTitle:post.user forState:UIControlStateNormal];
    
    // forum name or dateline
    if (post.fname) {
        cell.forum.hidden = NO;
        [cell.forum setTitle:post.fname forState:UIControlStateNormal];
        [cell.forum addTarget:self action:@selector(jumpToForum:) forControlEvents:UIControlEventTouchUpInside];
        cell.statisticLeftToPreposition.constant = BUCDefaultMargin + cell.forum.intrinsicContentSize.width;
    } else {
        cell.dateline.hidden = NO;
        cell.dateline.text = post.dateline;
        cell.statisticLeftToPreposition.constant = BUCDefaultMargin + cell.dateline.intrinsicContentSize.width;
    }
    
    // statistic
    cell.statistic.text = post.statistic;
    
    // last reply
    cell.lastPostDate.text = post.lastPostDateline;
    
    [cell.lastPoster setTitle:post.lastPoster forState:UIControlStateNormal];
    [cell.lastPoster addTarget:self action:@selector(jumpToPoster:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell addTarget:self action:@selector(jumpToPost:) forControlEvents:UIControlEventTouchUpInside];
    [cell layoutIfNeeded];
    CGRect frame = cell.frame;
    frame.size.height = cell.lastPoster.frame.origin.y + CGRectGetHeight(cell.lastPoster.frame);
    cell.frame = frame;
}


- (BOOL)isLoadedBefore:(BUCPost *)newpost against:(NSArray *)list{
    for (BUCPost *post in list) {
        if ([post.pid isEqualToString:newpost.pid]) {
            return YES;
        }
    }
    
    return NO;
}


@end

















