#import "BUCPostListController.h"
#import "BUCPostDetailController.h"
#import "BUCConstants.h"
#import "BUCPostListCell.h"
#import "BUCDataManager.h"
#import "BUCModels.h"
#import "UIImage+BUCImageCategory.h"

static NSUInteger const BUCPostListMinPostCount = 20;
static NSUInteger const BUCPostListMaxPostCount = 40;

@interface BUCPostListController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray *postList;

@property (nonatomic) NSString *from;
@property (nonatomic) NSString *to;

@property (nonatomic) NSUInteger postCount;
@property (nonatomic) NSUInteger location;
@property (nonatomic) NSUInteger length;

@property (nonatomic) BOOL flush;
@property (nonatomic) BOOL loading;
@property (nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) IBOutlet UIButton *previous;
@property (nonatomic) IBOutlet UIButton *next;
@property (nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end


@implementation BUCPostListController
#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    UIImage *background = [UIImage imageWithColor:[UIColor lightGrayColor]];
    [self.previous setBackgroundImage:background forState:UIControlStateHighlighted];
    self.previous.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.previous.layer.borderWidth = BUCBorderWidth;
    self.previous.titleLabel.backgroundColor = [UIColor whiteColor];
    self.previous.titleLabel.opaque = YES;
    self.previous.titleLabel.clearsContextBeforeDrawing = NO;
    self.previous.titleLabel.autoresizesSubviews = NO;
    
    [self.next setBackgroundImage:background forState:UIControlStateHighlighted];
    self.next.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.next.layer.borderWidth = BUCBorderWidth;
    self.next.titleLabel.backgroundColor = [UIColor whiteColor];
    self.next.titleLabel.opaque = YES;
    self.next.titleLabel.clearsContextBeforeDrawing = NO;
    self.next.titleLabel.autoresizesSubviews = NO;
    
    if (self.fid) {
        self.from = @"0";
        self.to = @"20";
        self.location = 0;
        self.length = 0;
    }

    self.tableView.sectionFooterHeight = 0.0f;
    self.tableView.sectionHeaderHeight = BUCDefaultMargin;
    
    [self refresh];
}


#pragma mark - data management
- (void)refresh {
    [self displayLoading];

    self.flush = YES;
    if (self.fid) {
        self.loading = YES;
        BUCPostListController * __weak weakSelf = self;
        [[BUCDataManager sharedInstance]
         childCountOfForum:self.fid
         thread:nil
         onSuccess:^(NSUInteger count) {
             weakSelf.postCount = count;
             [weakSelf loadList];
         } onError:^(NSError *error) {
             [weakSelf loadFailed:error];
         }];
        
    } else {
        [self loadList];
    }
}


- (void)didFinishedLoadList:(NSArray *)list {
    if (self.fid) {
        NSUInteger from = self.from.integerValue;
        if (self.flush) {
            self.location = from;
            self.length = BUCPostListMinPostCount;
        } else {
            self.length = self.length + BUCPostListMinPostCount;
        }
    }
    
    [self buildList:list];
    [self hideLoading];
    [self.loadingIndicator stopAnimating];
    self.loading = NO;
}


- (void)loadFailed:(NSError *)error {
    [self hideLoading];
    [self.loadingIndicator stopAnimating];
    [self alertMessage:error.localizedDescription];
    self.loading = NO;
}


- (void)loadList {
    BUCPostListController * __weak weakSelf = self;
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
    
    void (^successBlock)(NSArray *) = ^(NSArray *list) {
        [weakSelf didFinishedLoadList:list];
    };
    
    void (^errorBlock)(NSError *) = ^(NSError *error) {
        [weakSelf loadFailed:error];
    };

    self.loading = YES;
    if (self.fid) {
        [dataManager listOfForum:self.fid from:self.from to:self.to onSuccess:successBlock onError:errorBlock];
    } else {
        [dataManager listOfFrontOnSuccess:successBlock onError:errorBlock];
    }
}


- (IBAction)loadPrevious {
    unsigned long from = self.location - BUCPostListMaxPostCount;
    unsigned long to = from + BUCPostListMinPostCount;
    self.from = [NSString stringWithFormat:@"%lu", from];
    self.to = [NSString stringWithFormat:@"%lu", to];
    [self refresh];
}

- (IBAction)loadNext {
    unsigned long from = self.location + self.length;
    unsigned long to = from + BUCPostListMinPostCount;
    self.from = [NSString stringWithFormat:@"%lu", from];
    self.to = [NSString stringWithFormat:@"%lu", to];
    [self refresh];
}

- (void)loadMore {
    [self.next setTitle:@"More..." forState:UIControlStateNormal];
    unsigned long from = self.location + self.length;
    unsigned long to = from + BUCPostListMinPostCount;
    self.from = [NSString stringWithFormat:@"%lu", from];
    self.to = [NSString stringWithFormat:@"%lu", to];
    
    [self.loadingIndicator startAnimating];
    [self loadList];
}


#pragma mark - navigation
- (void)jumpToForum:(id)sender {
    BUCPostListController *postListController = [self.storyboard instantiateViewControllerWithIdentifier:BUCPostListControllerStoryboardID];
    UIButton *forumName = (UIButton *)sender;
    UIView *contentView = forumName.superview;
    BUCPost *post = [self.postList objectAtIndex:contentView.tag];
    postListController.fid = post.fid;
    postListController.fname = post.fname;
    [(UINavigationController *)self.parentViewController pushViewController:postListController animated:YES];
}


- (void)jumpToPoster:(id)sender {

}


#pragma mark - table view data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.postList.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPostListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"BUCPostListCell" forIndexPath:indexPath];
    [self configureCell:cell post:[self.postList objectAtIndex:indexPath.section]];
    cell.contentView.tag = indexPath.section;
    
    if (!self.loading && indexPath.section == self.postList.count - 1 && self.postCount > self.location + self.length && self.length < BUCPostListMaxPostCount) {
        [self loadMore];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPost *post = [self.postList objectAtIndex:indexPath.section];
    return post.cellHeight;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    BUCPostDetailController *postDetail = (BUCPostDetailController *)segue.destinationViewController;
    postDetail.post = [self.postList objectAtIndex:indexPath.section];
}


#pragma mark - private methods
- (void)updateNavigation {
    static CGFloat const BUCPostListSupplementaryViewHeight = 40.0f;
    
    UIView *view = self.tableView.tableHeaderView;;
    CGRect frame = view.frame;
    if (self.location == 0) {
        frame.size.height = BUCDefaultPadding;
        view.hidden = YES;
    } else {
        frame.size.height = BUCPostListSupplementaryViewHeight + BUCDefaultPadding + BUCDefaultMargin;
        view.hidden = NO;
    }
    view.frame = frame;
    [self.tableView setTableHeaderView:view];
    
    view = self.tableView.tableFooterView;
    frame = view.frame;
    if (self.postCount <= self.location + self.length) {
        frame.size.height = BUCDefaultPadding;
        view.hidden = YES;
    } else {
        frame.size.height = BUCPostListSupplementaryViewHeight + BUCDefaultPadding + BUCDefaultMargin;
        view.hidden = NO;
        [self.next setTitle:@"Next" forState:UIControlStateNormal];
    }
    view.frame = frame;
    [self.tableView setTableFooterView:view];
    
    if (self.fid) {
        unsigned long from = self.location + 1;
        unsigned long to = self.location + self.length;
        self.navigationItem.title = [NSString stringWithFormat:@"%@[%lu-%lu]", self.fname, from, to];
    } else {
        self.navigationItem.title = self.fname;
    }
}


- (void)buildList:(NSArray *)list {
    [self updateNavigation];

    NSMutableArray *postList;
    if (self.flush) {
        postList = [[NSMutableArray alloc] init];
        [self.tableView setContentOffset:CGPointZero];
    } else {
        postList = self.postList;
    }

    NSInteger count = postList.count;
    for (BUCPost *post in list) {
        if ([self isLoadedBefore:post against:postList]) {
            continue;
        }
        
        [self calculateFrameOfPost:post];
        [postList addObject:post];
    }
    
    self.postList = postList;
    
    if (!self.flush) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(count, postList.count - count)] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        self.flush = NO;
        [self.tableView reloadData];
    }
}


- (void)calculateFrameOfPost:(BUCPost *)post {
    static NSTextStorage *textStorage;
    static NSTextContainer *textContainer;
    static NSLayoutManager *layoutManager;;
    static CGFloat contentWidth;
    static dispatch_once_t onceSecurePredicate;
    
    BUCPostListController * __weak weakSelf = self;
    dispatch_once(&onceSecurePredicate, ^{
        contentWidth = CGRectGetWidth(weakSelf.tableView.frame) - 2 * BUCDefaultMargin - 2 * BUCDefaultPadding;
        textStorage = [[NSTextStorage alloc] init];
        layoutManager = [[NSLayoutManager alloc] init];
        [textStorage addLayoutManager:layoutManager];
        textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(contentWidth, FLT_MAX)];
        textContainer.lineFragmentPadding = 0;
        [layoutManager addTextContainer:textContainer];
    });
    
    if (post.title) {
        [textStorage setAttributedString:post.title];
        [layoutManager ensureLayoutForTextContainer:textContainer];
        
        CGRect frame = [layoutManager usedRectForTextContainer:textContainer];
        post.cellHeight = ceilf(frame.size.height) + 72.0f;
    } else {
        post.cellHeight = 72.0f;
    }
}


- (void)configureCell:(BUCPostListCell *)cell post:(BUCPost *)post {
    // title
    cell.title.preferredMaxLayoutWidth = CGRectGetWidth(self.tableView.frame) - 2 * BUCDefaultMargin - 2 * BUCDefaultPadding;
    cell.title.attributedText = post.title;
    
    // dateline
    cell.dateline.text = post.dateline;
    
    // statistic
    cell.statistic.text = post.statistic;
    
    // username
    [cell.author setTitle:post.user forState:UIControlStateNormal];
    
    // forum name or dateline
    if (post.fname) {
        cell.forum.hidden = NO;
        [cell.forum setTitle:post.fname forState:UIControlStateNormal];
        [cell.forum addTarget:self action:@selector(jumpToForum:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // last reply
    cell.lastPostDate.text = post.lastPostDateline;
    
    [cell.lastPoster setTitle:post.lastPoster forState:UIControlStateNormal];
    [cell.lastPoster addTarget:self action:@selector(jumpToPoster:) forControlEvents:UIControlEventTouchUpInside];
}


- (BOOL)isLoadedBefore:(BUCPost *)newpost against:(NSArray *)list{
    for (BUCPost *post in list) {
        if ([post.tid isEqualToString:newpost.tid]) {
            return YES;
        }
    }
    
    return NO;
}


@end

















