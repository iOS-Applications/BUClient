#import "BUCPostListController.h"
#import "BUCPostDetailController.h"
#import "BUCConstants.h"
#import "BUCDataManager.h"
#import "BUCModels.h"
#import "BUCAppDelegate.h"
#import "BUCNewPostController.h"
#import "BUCTextStack.h"
#import "BUCPostListCell.h"

static NSUInteger const BUCAPIMaxLoadRowCount = 20;
static NSUInteger const BUCPostListMaxRowCount = 40;

@interface BUCPostListController ()

@property (nonatomic) BUCAppDelegate *appDelegate;

@property (nonatomic) NSMutableArray *postList;
@property (nonatomic) NSMutableSet *tidSet;
@property (nonatomic) NSUInteger rowCount;
@property (nonatomic) NSUInteger postCount;
@property (nonatomic) NSUInteger from;
@property (nonatomic) NSUInteger to;

@property (nonatomic) BOOL flush;
@property (nonatomic) BOOL loading;

@property (nonatomic) CGFloat screenWidth;
@property (nonatomic) CGFloat contentWidth;
@property (nonatomic) CGFloat metaLineHeight;
@property (nonatomic) CGFloat nativeWidth;
@property (nonatomic) CGFloat nativeHeight;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *topLoadingIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *topRotateArrow;
@property (weak, nonatomic) IBOutlet UILabel *topLoadingLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *bottomLoadingIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *bottomRotateArrow;
@property (weak, nonatomic) IBOutlet UILabel *bottomLoadingLabel;
@property (strong, nonatomic) IBOutlet UIView *bottomPullToLoadHolder;

@end


@implementation BUCPostListController
#pragma mark - setup
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIContentSizeCategoryDidChangeNotification
                                                  object:nil];
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        [self.appDelegate hideLoading];
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self didRotateFromInterfaceOrientation:0];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textStyleChanged:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}


- (void)textStyleChanged:(NSNotification *)notification {
    [self.appDelegate displayLoading];
    self.metaLineHeight = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1].lineHeight;
    [self refreshFrom:self.from];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL layoutInvalid = NO;
    if (UIDeviceOrientationIsLandscape(orientation) && self.screenWidth != self.nativeHeight) {
        self.screenWidth = self.nativeHeight;
        layoutInvalid = YES;
    } else if (UIDeviceOrientationIsPortrait(orientation) && self.screenWidth != self.nativeWidth) {
        self.screenWidth = self.nativeWidth;
        layoutInvalid = YES;
    }

    if (layoutInvalid) {
        self.contentWidth = self.screenWidth - 2 * BUCDefaultPadding;
        [self relayoutList];
    }
}


- (void)setupLayout {
    self.nativeWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    self.nativeHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
    if (self.nativeWidth > self.nativeHeight) {
        CGFloat save = self.nativeWidth;
        self.nativeWidth = self.nativeHeight;
        self.nativeHeight = save;
    }
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIDeviceOrientationIsLandscape(orientation)) {
        self.screenWidth = self.nativeHeight;
    } else {
        self.screenWidth = self.nativeWidth;
    }
    self.contentWidth = self.screenWidth - 2 * BUCDefaultPadding;
    self.metaLineHeight = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1].lineHeight;
    self.tableView.sectionFooterHeight = 0.0f;
}


- (void)setupList {
    self.postList = [[NSMutableArray alloc] init];
    self.tidSet = [[NSMutableSet alloc] init];
    NSUInteger count;
    if (self.fid) {
        count = BUCPostListMaxRowCount;
    } else {
        count = BUCAPIMaxLoadRowCount;
    }
    for (int i = 0; i < count; i = i + 1) {
        [self.postList addObject:[[BUCPost alloc] initWithTextStack]];
    }
    
    self.from = 0;
    self.to = BUCAPIMaxLoadRowCount;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.topRotateArrow.transform = CGAffineTransformMakeRotation(M_PI);
    
    self.appDelegate = [UIApplication sharedApplication].delegate;
    
    [self setupLayout];
    [self setupList];

    [self.appDelegate displayLoading];
    [self refreshFrom:0];
}


#pragma mark - list manipulation
- (NSIndexSet *)newSectionsWithList:(NSArray *)list count:(NSUInteger)count {
    if (self.flush) {
        self.rowCount = 0;
        [self.tidSet removeAllObjects];
    }
    
    NSUInteger index = self.rowCount;
    
    for (NSUInteger i = 0; i < count; i = i + 1) {
        BUCPost *post = [list objectAtIndex:i];
        if ([self.tidSet containsObject:post.tid]) {
            continue;
        } else {
            [self.tidSet addObject:post.tid];
        }
        
        BUCPost *reusablePost = [self.postList objectAtIndex:index];
        reusablePost.uid = post.uid;
        reusablePost.tid = post.tid;
        reusablePost.forumName = post.forumName;
        reusablePost.title = post.title;
        [reusablePost.textStorage setAttributedString:post.content.richText];
        reusablePost.meta = post.meta;
        [self layoutPost:reusablePost];
        
        index = index + 1;
    }
    
    NSIndexSet *insertSections;
    if (!self.flush) {
        insertSections = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.rowCount, index - self.rowCount)];
    }
    self.rowCount = index;
    
    return insertSections;
}


- (void)loadListFrom:(NSUInteger)from {
    NSUInteger to = from + BUCAPIMaxLoadRowCount;
    BUCPostListController * __weak weakSelf = self;
    [[BUCDataManager sharedInstance]
     listOfForum:self.fid
     
     from:to > 0 ? [NSString stringWithFormat:@"%lu", (unsigned long)from] : nil
     
     to:to > 0 ? [NSString stringWithFormat:@"%lu", (unsigned long)(to)] : nil
     
     onSuccess:^(NSArray *list, NSUInteger count) {
         if (weakSelf) {
             NSIndexSet *newSections = [weakSelf newSectionsWithList:list count:count];
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (weakSelf.flush) {
                     weakSelf.from = from;
                     [weakSelf.tableView setContentOffset:CGPointZero];
                     [weakSelf.tableView reloadData];
                 } else {
                     [weakSelf.tableView insertSections:newSections withRowAnimation:UITableViewRowAnimationNone];
                 }
                 weakSelf.to = to;
                 
                 if (weakSelf.fid) {
                     weakSelf.tableView.tableFooterView.hidden = NO;
                 }
                 [weakSelf updateTitle];
                 [weakSelf endLoading];
             });
         }
     }
     
     onError:^(NSString *errorMsg) {
         if (weakSelf) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [weakSelf endLoading];
                 [weakSelf.appDelegate alertWithMessage:errorMsg];
             });
         }
     }];
}


- (void)refreshFrom:(NSUInteger)from {
    self.flush = YES;
    self.loading = YES;
    BUCPostListController * __weak weakSelf = self;
    if (self.fid) {
        [[BUCDataManager sharedInstance]
         childCountOfForum:self.fid
         thread:nil
         
         onSuccess:^(NSUInteger count) {
             weakSelf.postCount = count + 1;
             [weakSelf loadListFrom:from];
         } onError:^(NSString *errorMsg) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [weakSelf endLoading];
                 [weakSelf.appDelegate alertWithMessage:errorMsg];
             });
         }];
    } else {
        [self loadListFrom:from];
    }
}


- (void)displayTopLoading {
    self.topRotateArrow.hidden = YES;
    self.tableView.bounces = NO;
    [self.topLoadingIndicator startAnimating];
    self.tableView.contentInset = UIEdgeInsetsMake(50, 0, 0, 0);
    self.topLoadingLabel.text = @"加载中，请等待...";
}


- (void)displayBottomLoading {
    self.bottomRotateArrow.hidden = YES;
    self.tableView.bounces = NO;
    [self.bottomLoadingIndicator startAnimating];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0);
    self.bottomLoadingLabel.text = @"加载中，请等待...";
}


- (void)loadBackward {
    NSUInteger from;
    if (self.from == 0) {
        from = self.from;
    } else {
        from = self.from - BUCPostListMaxRowCount;
    }
    [self refreshFrom:from];
}


- (void)loadMore {
    self.flush = NO;
    self.loading = YES;
    [self displayBottomLoading];
    self.bottomLoadingLabel.text = @"加载中，请等待...";
    [self loadListFrom:self.to];
}


- (void)loadForward {
    NSUInteger from;
    if (self.to >= self.postCount) {
        from = self.from;
    } else {
        from = self.to;
    }
    [self refreshFrom:from];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.loading) {
        return;
    }
    
    UIImageView *topArrow = self.topRotateArrow;
    if (scrollView.contentOffset.y <= -50.0f) {
        [UIView animateWithDuration:0.2 animations:^{
            topArrow.transform = CGAffineTransformIdentity;
        }];
        if (self.from == 0) {
            self.topLoadingLabel.text = @"松开后刷新";
        } else {
            self.topLoadingLabel.text = @"松开后向前加载";
        }
    } else if (scrollView.contentOffset.y < 0.0f) {
        [UIView animateWithDuration:0.2 animations:^{
            topArrow.transform = CGAffineTransformMakeRotation(M_PI);
        }];
        self.topLoadingLabel.text = @"向下拉动";
    }
    
    UIImageView *bottomArrow = self.bottomRotateArrow;
    CGFloat maxOffset = scrollView.contentSize.height - CGRectGetHeight(self.tableView.bounds);
    if (scrollView.contentOffset.y >= maxOffset + 50.0f) {
        [UIView animateWithDuration:0.2 animations:^{
            bottomArrow.transform = CGAffineTransformMakeRotation(M_PI);
        }];

        if (self.to > self.postCount) {
            self.bottomLoadingLabel.text = @"松开后刷新";
        } else {
            self.bottomLoadingLabel.text = @"松开后向后加载";
        }
    } else if (scrollView.contentOffset.y > maxOffset){
        [UIView animateWithDuration:0.2 animations:^{
            bottomArrow.transform = CGAffineTransformIdentity;
        }];
        self.bottomLoadingLabel.text = @"向上拉动";
    }
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.loading) {
        return;
    } else if (scrollView.contentOffset.y <= - 50.0f) {
        [self displayTopLoading];
        [self loadBackward];
    } else if (self.fid && scrollView.contentOffset.y >= scrollView.contentSize.height - CGRectGetHeight(self.tableView.bounds) + 50.0f) {
        [self displayBottomLoading];
        [self loadForward];
    }
}


- (void)endLoading {
    [self.appDelegate hideLoading];
    self.loading = NO;
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.topRotateArrow.hidden = NO;
    self.bottomRotateArrow.hidden = NO;
    [self.topLoadingIndicator stopAnimating];
    [self.bottomLoadingIndicator stopAnimating];
    self.topLoadingLabel.text = @"向下拉动";
    self.bottomLoadingLabel.text = @"向上拉动";
    self.tableView.bounces = YES;
}


#pragma mark - table view data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.rowCount;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


#pragma mark - update views
- (void)updateTitle {
    if (self.fid) {
        unsigned long from = self.from + 1;
        unsigned long to = self.from + self.rowCount;

        self.navigationItem.title = [NSString stringWithFormat:@"%@[%lu-%lu]", self.fname, from, to];
    } else {
        self.navigationItem.title = self.fname;
    }
}


- (void)layoutPost:(BUCPost *)post {
    post.textContainer.size = CGSizeMake(self.contentWidth, FLT_MAX);
    [post.layoutManager ensureLayoutForTextContainer:post.textContainer];
    CGRect frame = [post.layoutManager usedRectForTextContainer:post.textContainer];
    frame.size.height = ceilf(frame.size.height);
    
    post.cellWidth = self.screenWidth;
    post.cellHeight = BUCDefaultMargin * 3.0f + frame.size.height + self.metaLineHeight;
    post.bounds = CGRectMake(0.0f, 0.0f, self.screenWidth, post.cellHeight);
}


- (void)relayoutList {
    BUCPostListController * __weak weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        dispatch_apply(self.rowCount, queue, ^(size_t i) {
            BUCPost *post = [self.postList objectAtIndex:i];
            [weakSelf layoutPost:post];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    });
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPost *post = [self.postList objectAtIndex:indexPath.section];    
    return post.cellHeight + 0.5f;
}


- (UIImage *)renderPost:(BUCPost *)post {
    UIImage *output;
    CGFloat separatorPosition = post.cellHeight - self.metaLineHeight - BUCDefaultMargin * 2.0f;
    UIGraphicsBeginImageContextWithOptions(post.bounds.size, NO, 0);
    [post.layoutManager drawGlyphsForGlyphRange:NSMakeRange(0, post.textStorage.length)
                                        atPoint:CGPointMake(BUCDefaultPadding, BUCDefaultMargin)];
    [post.meta drawAtPoint:CGPointMake(BUCDefaultPadding, separatorPosition + BUCDefaultMargin)];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, separatorPosition + 2.0f, self.screenWidth, 0.5f)];
    [[UIColor lightGrayColor] setFill];
    [path fill];
    output = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return output;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPostListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"
                                                                 forIndexPath:indexPath];
    BUCPost *post = [self.postList objectAtIndex:indexPath.section];
    cell.contentView.layer.contents = (id)[self renderPost:post].CGImage;
    cell.contentView.hidden = NO;
    
    if (indexPath.section == self.rowCount - 1 &&
        !self.loading &&
        self.to < self.postCount &&
        self.rowCount == 20) {
        [self loadMore];
    }
    
    return cell;
}


#pragma mark - navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"postListToPostDetail"]) {
        BUCPostDetailController *postDetail = (BUCPostDetailController *)segue.destinationViewController;
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        postDetail.rootPost = [self.postList objectAtIndex:indexPath.section];
    } else if ([segue.identifier isEqualToString:@"postListToNewPost"]) {
        BUCNewPostController *newPost = (BUCNewPostController *)(((UINavigationController *)segue.destinationViewController).topViewController);
        newPost.fid = self.fid;
        if (self.fid) {
            newPost.forumName = self.fname;
        }
        newPost.unwindIdentifier = @"newPostToPostList";
        newPost.navigationItem.title = @"发布新帖";
    }
}


- (IBAction)unwindToPostList:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"newPostToPostList"]) {
    }
}


@end

















