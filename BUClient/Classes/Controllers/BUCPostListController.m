#import "BUCPostListController.h"
#import "BUCPostDetailController.h"
#import "BUCConstants.h"
#import "BUCPostListCell.h"
#import "BUCDataManager.h"
#import "BUCModels.h"

static CGFloat const BUCPostListSupplementaryViewHeight = 40.0f;

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


#pragma mark - actions and unwind methods
- (void)refresh {
    [self displayLoading];

    self.isRefresh = YES;
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
        [dataManager getForumList:self.fid from:self.from to:self.to onSuccess:listBlock onError:errorBlock];
    } else {
        [dataManager getFrontListOnSuccess:listBlock onError:errorBlock];
    }
}


- (void)jumpToPost:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:BUCMainStoryboardPath bundle:nil];
    BUCPostDetailController *postDetailController = [storyboard instantiateViewControllerWithIdentifier:BUCPostDetailControllerStoryboardID];
    BUCPostListCell *listItem = (BUCPostListCell *)sender;
    BUCPost *post = [self.postList objectAtIndex:listItem.tag];
    postDetailController.post = post;
    [(UINavigationController *)self.parentViewController pushViewController:postDetailController animated:YES];
}


- (void)jumpToForum:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:BUCMainStoryboardPath bundle:nil];
    BUCPostListController *postListController = [storyboard instantiateViewControllerWithIdentifier:BUCPostListControllerStoryboardID];
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
    self.from = [NSString stringWithFormat:@"%lu", (unsigned long)(self.location - 40)];
    self.to = [NSString stringWithFormat:@"%lu", (unsigned long)(self.location - 20)];
    [self refresh];
}


- (void)loadNext {
    self.from = [NSString stringWithFormat:@"%lu", (unsigned long)(self.location + 40)];
    self.to = [NSString stringWithFormat:@"%lu", (unsigned long)(self.location + 60)];
    [self refresh];
}


- (void)loadMore {
    self.from = [NSString stringWithFormat:@"%lu", (unsigned long)(self.location + 20)];
    self.to = [NSString stringWithFormat:@"%lu", (unsigned long)(self.location + 40)];
    [self.moreIndicator startAnimating];
    [self loadList];
}


#pragma mark - scroll view delegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat refreshFireHeight = 40.0f;
    if (scrollView.contentOffset.y <= -refreshFireHeight) {
        [self refresh];
    } else if (self.fid && !decelerate && self.length != 40 && self.postCount >= self.location + 20) {
        CGFloat loadMoreHeight = ceilf(CGRectGetHeight(self.listWrapper.frame) / 2);
        if (scrollView.contentOffset.y >= loadMoreHeight) {
            [self loadMore];
        }
    }
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.fid && self.length != 40 && self.postCount >= self.location + 20) {
        CGFloat loadMoreHeight = ceilf(CGRectGetHeight(self.listWrapper.frame) / 2);
        if (scrollView.contentOffset.y >= loadMoreHeight) {
            [self loadMore];
        }
    }
}


#pragma mark - private methods
- (void)buildList:(NSArray *)list {
    // header
    if (self.location >= 40) {
        self.previousHolder.hidden = NO;
        self.listTopToHeader.constant = BUCDefaultPadding;
    } else {
        self.previousHolder.hidden = YES;
        self.listTopToHeader.constant = -BUCPostListSupplementaryViewHeight;
    }
    
    CGFloat listHeight = 0.0f;
    // list content
    NSMutableArray *postList;
    if (self.isRefresh) {
        postList = [[NSMutableArray alloc] init];
        self.isRefresh = NO;
        [self.scrollView setContentOffset:CGPointZero];
    } else {
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
            [cell setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self.cellList addObject:cell];
            [self.listWrapper addSubview:cell];
            NSDictionary *views = @{@"cell":cell};
            
            [self.listWrapper addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat:@"|[cell]|" options:0 metrics:nil views:views]];

            cell.yConstraint = [NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.listWrapper attribute:NSLayoutAttributeTop multiplier:1.0f constant:listHeight];
            cell.heightConstraint = [NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:0];
            [self.listWrapper addConstraint:cell.yConstraint];
            [cell addConstraint:cell.heightConstraint];
        } else {
            cell = [self.cellList objectAtIndex:index];
            cell.yConstraint.constant = listHeight;
        }
        
        cell.tag = index;
        cell.hidden = NO;
        [self configureCell:cell post:post];
        
        CGFloat cellHeight = CGRectGetMinY(cell.lastPoster.frame) + CGRectGetHeight(cell.lastPoster.frame);
        cell.heightConstraint.constant = cellHeight;
        
        [postList addObject:post];
        index = index + 1;
        listHeight = listHeight + cellHeight + BUCDefaultMargin;
    }
    
    self.listHeight.constant = listHeight - BUCDefaultMargin;
    
    // footer
    if (self.postCount > 0 && self.postCount >= self.location + self.length) {
        self.nextHolder.hidden = NO;
        if (self.length == 20) {
            self.moreOrNext.text = @"More...";
            [self.nextHolder removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [self.nextHolder addTarget:self action:@selector(loadMore) forControlEvents:UIControlEventTouchUpInside];
        } else if (self.length == 40) {
            self.moreOrNext.text = @"下一页";
            [self.nextHolder removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [self.nextHolder addTarget:self action:@selector(loadNext) forControlEvents:UIControlEventTouchUpInside];
        }
        self.listBottomToFooter.constant = BUCDefaultPadding;
    } else {
        self.nextHolder.hidden = YES;
        self.listBottomToFooter.constant = -BUCPostListSupplementaryViewHeight;
    }
    
    // update title of top bar
    if (self.fid) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@[%lu]", self.fname, (unsigned long)(self.location / 40 + 1)];
    }
    
    self.postList = postList;
}


- (void)configureCell:(BUCPostListCell *)cell post:(BUCPost *)post {
    [cell layoutIfNeeded];
    // title
    cell.title.preferredMaxLayoutWidth = CGRectGetWidth(cell.frame) - 2 * BUCDefaultMargin;
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

















