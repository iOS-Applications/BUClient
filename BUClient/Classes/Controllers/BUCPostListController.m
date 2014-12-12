#import "BUCPostListController.h"
#import "BUCPostDetailController.h"
#import "BUCConstants.h"
#import "BUCPostListCell.h"
#import "BUCDataManager.h"
#import "BUCModels.h"
#import "UIImage+BUCImageCategory.h"
#import "BUCAppDelegate.h"
#import "BUCNewPostController.h"

static NSUInteger const BUCPostListMinPostCount = 20;
static NSUInteger const BUCPostListMaxPostCount = 40;

@interface BUCPostListController ()

@property (nonatomic) NSMutableArray *postList;
@property (nonatomic) BUCPost *postNew;

@property (nonatomic) NSUInteger from;
@property (nonatomic) NSUInteger to;
@property (nonatomic) NSUInteger postCount;

@property (nonatomic) BOOL flush;
@property (nonatomic) BOOL loading;

@property (nonatomic) IBOutlet UIButton *previous;
@property (nonatomic) IBOutlet UIButton *next;
@property (nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@property (nonatomic) BUCAppDelegate *appDelegate;

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
    
    self.from = 0;
    if (self.fid) {
        self.to = 20;
    } else {
        self.to = 0;
    }

    self.tableView.sectionFooterHeight = 0.0f;
    self.tableView.sectionHeaderHeight = BUCDefaultMargin;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    self.appDelegate = [UIApplication sharedApplication].delegate;
    [self.appDelegate displayLoading];
    [self refreshFrom:self.from to:self.to];
}


- (void)viewDidAppear:(BOOL)animated {
    if (self.postNew) {
        [self performSegueWithIdentifier:@"postListToPostDetail" sender:nil];
    }
}


- (void)dealloc {
    if (self.loading) {
        [self.appDelegate hideLoading];
    }
}

#pragma mark - data management
- (void)refresh {
    [self refreshFrom:self.from to:self.from + BUCPostListMinPostCount];
}


- (void)refreshFrom:(NSUInteger)from to:(NSUInteger)to {
    self.flush = YES;
    if (self.fid) {
        self.loading = YES;
        BUCPostListController * __weak weakSelf = self;
        [[BUCDataManager sharedInstance]
         childCountOfForum:self.fid
         thread:nil
         onSuccess:^(NSUInteger count) {
             [weakSelf loadListFrom:from to:to postCount:count + 1];
         } onError:^(NSError *error) {
             [weakSelf endLoading];
             [weakSelf.appDelegate alertWithMessage:error.localizedDescription];
         }];
        
    } else {
        [self loadListFrom:from to:to postCount:0];
    }
}


- (IBAction)loadPrevious {
    long from = self.from - BUCPostListMaxPostCount;
    if (from < 0) {
        from = 0;
    }
    long to = from + BUCPostListMinPostCount;
    [self.appDelegate displayLoading];
    [self refreshFrom:from to:to];
}

- (IBAction)loadNext {
    unsigned long from = self.to;
    unsigned long to = from + BUCPostListMinPostCount;
    [self.appDelegate displayLoading];
    [self refreshFrom:from to:to];
}

- (void)loadMore {
    [self.next setTitle:@"More..." forState:UIControlStateNormal];
    unsigned long from = self.to;
    unsigned long to = from + BUCPostListMinPostCount;
    
    [self.loadingIndicator startAnimating];
    [self loadListFrom:from to:to postCount:self.postCount];
}


- (void)loadListFrom:(NSUInteger)from to:(NSUInteger)to  postCount:(NSInteger)count{
    BUCPostListController * __weak weakSelf = self;
    self.loading = YES;
    
    [[BUCDataManager sharedInstance]
     listOfForum:self.fid
     
     from:[NSString stringWithFormat:@"%lu", (unsigned long)from]
     
     to:[NSString stringWithFormat:@"%lu", (unsigned long)to]
     
     onSuccess:^(NSArray *list) {
         [weakSelf updateNavigationStateWithFrom:from to:to postCount:count];
         [weakSelf buildList:list];
         [weakSelf endLoading];
     }
     
     onError:^(NSError *error) {
         [weakSelf endLoading];
         [weakSelf.appDelegate alertWithMessage:error.localizedDescription];
     }];
}


- (void)updateNavigationStateWithFrom:(NSInteger)from to:(NSInteger)to postCount:(NSInteger)count {
    if (self.flush) {
        self.from = from;
    }
    self.to = to;
    self.postCount = count;
}


- (void)endLoading {
    [self.appDelegate hideLoading];
    [self.refreshControl endRefreshing];
    [self.loadingIndicator stopAnimating];
    self.loading = NO;
}


- (void)buildList:(NSArray *)list {
    [self updateUI];
    
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


- (BOOL)isLoadedBefore:(BUCPost *)newpost against:(NSArray *)list{
    for (BUCPost *post in list) {
        if ([post.tid isEqualToString:newpost.tid]) {
            return YES;
        }
    }
    
    return NO;
}


#pragma mark - table view data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.postList.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPostListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    [self configureCell:cell post:[self.postList objectAtIndex:indexPath.section]];
    cell.contentView.tag = indexPath.section;
    
    if (self.fid && !self.loading && indexPath.section == self.postList.count - 1 && self.postCount > self.to && self.to < self.from + BUCPostListMaxPostCount) {
        [self loadMore];
    }
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPost *post = [self.postList objectAtIndex:indexPath.section];
    return post.cellHeight;
}


#pragma mark - update UI
- (void)updateUI {
    static CGFloat const BUCPostListSupplementaryViewHeight = 40.0f;
    
    UIView *view = self.tableView.tableHeaderView;;
    CGRect frame = view.frame;
    if (self.from == 0) {
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
    if (self.postCount <= self.to) {
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
        unsigned long from = self.from + 1;
        unsigned long to;
        if (self.to >= self.postCount) {
            to = self.from + self.postList.count;
        } else {
            to = self.to;
        }
        self.navigationItem.title = [NSString stringWithFormat:@"%@[%lu-%lu]", self.fname, from, to];
    } else {
        self.navigationItem.title = self.fname;
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
    }
    
    // last reply
    cell.lastPostDate.text = post.lastPostDateline;
    
    [cell.lastPoster setTitle:post.lastPoster forState:UIControlStateNormal];
}


#pragma mark - navigation
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"postListToPostDetail" sender:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"postListToPostDetail"]) {
        BUCPostDetailController *postDetail = (BUCPostDetailController *)segue.destinationViewController;
        if (self.postNew) {
            postDetail.post = self.postNew;
            self.postNew = nil;
        } else {
            NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            postDetail.post = [self.postList objectAtIndex:indexPath.section];
        }
    } else if ([segue.identifier isEqualToString:@"postListToNewPost"]) {
        BUCNewPostController *newPost = (BUCNewPostController *)(((UINavigationController *)segue.destinationViewController).topViewController);
        newPost.fid = self.fid;
        if (self.fid) {
            newPost.forumName = self.fname;
        }
        newPost.unwindIdentifier = @"newPostToPostList";
        newPost.navigationItem.title = @"New Post";
    }
}


- (IBAction)unwindToPostList:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"newPostToPostList"]) {
        BUCNewPostController *newPostController = (BUCNewPostController *)segue.sourceViewController;
        self.postNew = [[BUCPost alloc] init];
        self.postNew.tid = [(NSNumber *)newPostController.tid stringValue];
        self.postNew.title = [[NSAttributedString alloc] initWithString:newPostController.postTitle];
        self.postNew.user = [[NSUserDefaults standardUserDefaults] stringForKey:BUCCurrentUserDefaultKey];
        self.postNew.uid = [[NSUserDefaults standardUserDefaults] stringForKey:BUCUidDefaultKey];
    }
}


@end

















