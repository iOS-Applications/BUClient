#import "BUCPostListController.h"
#import "BUCPostDetailController.h"
#import "BUCConstants.h"
#import "BUCPostListCell.h"
#import "BUCDataManager.h"
#import "BUCModels.h"


static CGFloat const BUCPostListSupplementaryViewHeight = 40.0f;
static NSString * const BUCCellNib = @"BUCPostListCell";

@interface BUCPostListController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet BUCPostListCell *previousHolder;
@property (weak, nonatomic) IBOutlet UILabel *previous;
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
    
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(BUCTopBarHeight, 0, 0, 0);
    self.cellList = [[NSMutableArray alloc] init];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    CGRect frame = self.previousHolder.frame;
    frame.origin = CGPointMake(BUCDefaultPadding, BUCDefaultPadding + BUCTopBarHeight);
    frame.size.width = frame.size.width - 2 * BUCDefaultPadding;
    
    self.previousHolder.frame = frame;
    [self.previousHolder addTarget:self action:@selector(loadPrevious) forControlEvents:UIControlEventTouchUpInside];
    self.previous.center = CGPointMake(CGRectGetMidX(self.previousHolder.bounds), CGRectGetMidY(self.previousHolder.bounds));
    
    self.nextHolder.frame = frame;
    self.moreOrNext.center = self.previous.center;
    [self.nextHolder addTarget:self action:@selector(loadNext) forControlEvents:UIControlEventTouchUpInside];

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


- (void)loadPrevious {
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
    CGSize contentSize = self.scrollView.contentSize;
    contentSize.height = BUCTopBarHeight + 2 * BUCDefaultPadding;
    CGRect listFrame = CGRectZero;
    CGSize listSize = CGSizeZero;
    listSize.width = CGRectGetWidth(self.scrollView.frame) - 2 * BUCDefaultPadding;

    // header
    if (self.location >= 40) {
        self.previousHolder.hidden = NO;
        listFrame.origin = CGPointMake(BUCDefaultPadding, BUCDefaultPadding + BUCDefaultMargin + BUCPostListSupplementaryViewHeight + BUCTopBarHeight);
        contentSize.height = contentSize.height + BUCPostListSupplementaryViewHeight + BUCDefaultMargin;
    } else {
        self.previousHolder.hidden = YES;
        listFrame.origin = CGPointMake(BUCDefaultPadding, BUCTopBarHeight + BUCDefaultPadding);
    }
    
    // list content
    NSMutableArray *postList;
    if (self.isRefresh) {
        postList = [[NSMutableArray alloc] init];
        self.isRefresh = NO;
        [self.scrollView setContentOffset:CGPointZero];
    } else {
        postList = self.postList;
        listSize.height = self.listWrapper.frame.size.height + BUCDefaultMargin;
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
        
        cell.tag = index;
        cell.hidden = NO;
        CGRect cellFrame = CGRectMake(0, listSize.height, listSize.width, 0);
        [self configureCell:cell post:post frame:cellFrame];
        listSize.height = listSize.height + cell.frame.size.height + BUCDefaultMargin;
        
        [postList addObject:post];
        index = index + 1;
    }
    
    for (; index < cellCount; index = index + 1) {
        BUCPostListCell *cell = [self.cellList objectAtIndex:index];
        cell.hidden = YES;
    }
    
    listSize.height = listSize.height - BUCDefaultMargin;
    listFrame.size = listSize;
    self.listWrapper.frame = listFrame;
    contentSize.height = contentSize.height + listSize.height;

    // footer
    if (self.postCount > 0 && self.postCount >= self.location + self.length) {
        self.nextHolder.hidden = NO;
        CGRect frame = self.nextHolder.frame;
        frame.origin = CGPointMake(BUCDefaultPadding, listFrame.origin.y + listSize.height + BUCDefaultMargin);
        self.nextHolder.frame = frame;
        contentSize.height = contentSize.height + BUCPostListSupplementaryViewHeight + BUCDefaultMargin;
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

    // update content size of scroll view
    self.scrollView.contentSize = contentSize;
    
    // update title of top bar
    if (self.fid) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@[%lu]", self.fname, (unsigned long)(self.location / 40 + 1)];
    }
    
    self.postList = postList;
}


- (void)configureCell:(BUCPostListCell *)cell post:(BUCPost *)post frame:(CGRect)aRect {
    CGFloat contentWidth = aRect.size.width - 2 * BUCDefaultPadding;
    
    // title
    CGRect frame = cell.title.frame;
    frame.origin = CGPointMake(BUCDefaultPadding, BUCDefaultPadding);
    CGSize size = frame.size;
    size.width = contentWidth;
    frame.size = size;
    
    cell.title.frame = frame;
    cell.title.attributedText = post.title;
    [cell.title sizeToFit];
    
    frame.origin.y = frame.origin.y + ceilf(cell.title.frame.size.height) + BUCDefaultMargin;
    
    // username
    [cell.username setTitle:post.user forState:UIControlStateNormal];
    [cell.username sizeToFit];
    size.width = ceilf(cell.username.frame.size.width);
    size.height = ceilf(cell.username.titleLabel.frame.size.height);
    frame.size = size;
    cell.username.frame = frame;
    [cell.username addTarget:self action:@selector(jumpToPoster:) forControlEvents:UIControlEventTouchUpInside];
    
    frame.origin.x = frame.origin.x + size.width + BUCDefaultMargin;
    
    // preposition
    [cell.preposition sizeToFit];
    size.width = ceilf(cell.preposition.frame.size.width);
    frame.size = size;
    cell.preposition.frame = frame;
    
    frame.origin.x = frame.origin.x + size.width + BUCDefaultMargin;
    
    // forum name or dateline
    if (post.fname) {
        cell.forum.hidden = NO;
        [cell.forum setTitle:post.fname forState:UIControlStateNormal];
        [cell.forum sizeToFit];
        size.width = ceilf(cell.forum.frame.size.width);
        frame.size = size;
        cell.forum.frame = frame;
        [cell.forum addTarget:self action:@selector(jumpToForum:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        cell.dateline.hidden = NO;
        cell.dateline.text = post.dateline;
        [cell.dateline sizeToFit];
        size.width = ceilf(cell.dateline.frame.size.width);
        frame.size = size;
        cell.dateline.frame = frame;
    }
    
    frame.origin.x = frame.origin.x + size.width + BUCDefaultMargin;
    
    // statistic
    cell.statistic.text = post.statistic;
    [cell.statistic sizeToFit];
    size.width = ceilf(cell.statistic.frame.size.width);
    frame.size = size;
    cell.statistic.frame = frame;
    
    // separator
    frame.origin = CGPointMake(BUCDefaultPadding, frame.origin.y + size.height + BUCDefaultMargin);
    frame.size = CGSizeMake(contentWidth, BUCBorderWidth);
    cell.separator.frame = frame;
    
    frame.origin.y = frame.origin.y + BUCDefaultMargin;
    
    // last reply
    cell.lastPostDate.text = post.lastPostDateline;
    [cell.lastPostDate sizeToFit];
    size.width = ceilf(cell.lastPostDate.frame.size.width);
    frame.size = size;
    cell.lastPostDate.frame = frame;
    
    frame.origin.x = frame.origin.x + size.width + BUCDefaultMargin;
    
    [cell.lastPoster setTitle:post.lastPoster forState:UIControlStateNormal];
    [cell.lastPoster sizeToFit];
    size.width = ceilf(cell.lastPoster.frame.size.width);
    frame.size = size;
    cell.lastPoster.frame = frame;
    [cell.lastPoster addTarget:self action:@selector(jumpToPoster:) forControlEvents:UIControlEventTouchUpInside];
    
    // reset frame
    aRect.size.height = frame.origin.y + size.height + BUCDefaultPadding;
    cell.frame = aRect;
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

















