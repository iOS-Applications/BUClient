#import "BUCPostListController.h"
#import "BUCPostDetailController.h"
#import "BUCConstants.h"
#import "BUCDataManager.h"
#import "BUCModels.h"
#import "UIImage+BUCImageCategory.h"
#import "BUCAppDelegate.h"
#import "BUCNewPostController.h"
#import "BUCTextStack.h"
#import "BUCPostListCell.h"

static NSUInteger const BUCPostListUnitLength = 20;

@interface BUCPostListController ()

@property (nonatomic) BUCAppDelegate *appDelegate;

@property (nonatomic) NSMutableArray *postListA;
@property (nonatomic) NSMutableSet *postIndexSetA;
@property (nonatomic) NSMutableArray *postListB;
@property (nonatomic) NSMutableSet *postIndexSetB;

@property (nonatomic) BOOL loading;
@property (nonatomic) NSUInteger from;
@property (nonatomic) NSUInteger to;
@property (nonatomic) NSUInteger rows;
@property (nonatomic) NSUInteger countA;
@property (nonatomic) NSUInteger countB;

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
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.topRotateArrow.transform = CGAffineTransformMakeRotation(M_PI);
    
    self.nativeWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    self.nativeHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
    if (self.nativeWidth > self.nativeHeight) {
        CGFloat save = self.nativeWidth;
        self.nativeWidth = self.nativeHeight;
        self.nativeHeight = save;
    }
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(deviceOrientation)) {
        self.screenWidth = self.nativeHeight;
    } else if (UIDeviceOrientationIsPortrait(deviceOrientation)) {
        self.screenWidth = self.nativeWidth;
    } else {
        self.screenWidth = self.nativeWidth;
    }
    self.contentWidth = self.screenWidth - 2 * BUCDefaultPadding;
    self.metaLineHeight = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1].lineHeight;
    
    self.tableView.sectionFooterHeight = 0.0f;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textStyleChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    self.appDelegate = [UIApplication sharedApplication].delegate;
    
    self.postListA = [[NSMutableArray alloc] init];
    if (self.fid) {
        self.postIndexSetA = [[NSMutableSet alloc] init];
        self.postListB = [[NSMutableArray alloc] init];
        self.postIndexSetB = [[NSMutableSet alloc] init];
    }
    for (int i = 0; i < BUCPostListUnitLength; i = i + 1) {
        [self.postListA addObject:[[BUCPost alloc] init]];
        if (self.fid) {
            [self.postListB addObject:[[BUCPost alloc] init]];
        }
    }

    [self.appDelegate displayLoading];
    self.from = 0;
    self.to = BUCPostListUnitLength;
    [self loadListFrom:self.from to:self.to];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.appDelegate hideLoading];
}


- (void)textStyleChanged:(NSNotification *)notification {
    [self.appDelegate displayLoading];
    self.metaLineHeight = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1].lineHeight;
    self.countA = 0;
    self.countB = 0;
    [self loadListFrom:self.from to:self.from + BUCPostListUnitLength];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
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
        [self.tableView reloadData];
    }
}


#pragma mark - list manipulation
- (void)swapList {
    NSMutableArray *list = self.postListA;
    self.postListA = self.postListB;
    self.postListB = list;
    NSMutableSet *set = self.postIndexSetA;
    self.postIndexSetA = self.postIndexSetB;
    self.postIndexSetB = set;
    NSUInteger count = self.countA;
    self.countA = self.countB;
    self.countB = count;
}


- (void)updateWithList:(NSArray *)list from:(NSUInteger)from to:(NSUInteger)to {
    NSUInteger index;
    UITableViewScrollPosition position;
    if (self.countA == 0 || (self.from < from && self.countB > 0)) {
        self.rows = self.countB;
        NSUInteger count = [self buildList:self.postListA withList:list indexSet:self.postIndexSetB emptyIndexSet:self.postIndexSetA];
        if (self.countA == 0) {
            self.countA = count;
            self.from = from;
            if (self.countB == 0) {
                self.to = to;
            }
            index = 0;
            position = UITableViewScrollPositionTop;
        } else {
            self.from = self.from + BUCPostListUnitLength;
            self.to = to;
            [self swapList];
            index = count - 1;
            position = UITableViewScrollPositionBottom;
        }
    } else {
        self.rows = self.countA;
        NSUInteger count = [self buildList:self.postListB withList:list indexSet:self.postIndexSetA emptyIndexSet:self.postIndexSetB];
        if (self.countB == 0) {
            self.to = to;
            self.countB = count;
            index = self.countA - 1;
            position = UITableViewScrollPositionBottom;
        } else {
            self.from = from;
            self.to = to + BUCPostListUnitLength;
            [self swapList];
            index = count;
            position = UITableViewScrollPositionTop;
        }
    }
    
    if (self.tableView.numberOfSections < self.rows) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.tableView.numberOfSections, self.rows - self.tableView.numberOfSections)] withRowAnimation:UITableViewRowAnimationNone];
    } else if (self.tableView.numberOfSections > self.rows) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfSections - self.rows)] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    if (index == 0) {
        [self.tableView setContentOffset:CGPointZero];
    } else { 
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index] atScrollPosition:position animated:NO];
    }
}


- (void)loadListFrom:(NSUInteger)from to:(NSUInteger)to {
    BUCPostListController * __weak weakSelf = self;
    self.loading = YES;
    
    [[BUCDataManager sharedInstance]
     listOfForum:self.fid
     
     from:[NSString stringWithFormat:@"%lu", (unsigned long)from]
     
     to:[NSString stringWithFormat:@"%lu", (unsigned long)to]
     
     onSuccess:^(NSArray *list) {
         if (weakSelf.fid) {
             [weakSelf updateWithList:list from:from to:to];
             weakSelf.tableView.tableFooterView.hidden = NO;
         } else {
             weakSelf.rows = 0;
             [weakSelf buildList:weakSelf.postListA withList:list indexSet:nil emptyIndexSet:nil];
             [weakSelf.tableView reloadData];
         }
         [weakSelf updateTitle];
         [weakSelf endLoading];
     }
     
     onError:^(NSError *error) {
         [weakSelf endLoading];
         [weakSelf.appDelegate alertWithMessage:error.localizedDescription];
     }];
}


- (NSUInteger)buildList:(NSMutableArray *)list withList:(NSArray *)newList indexSet:(NSSet *)indexSet emptyIndexSet:(NSMutableSet *)emptySet {
    [emptySet removeAllObjects];
    NSUInteger index = 0;
    for (BUCPost *post in newList) {
        if ([indexSet containsObject:post.tid]) {
            continue;
        }
        [emptySet addObject:post.tid];
        
        BUCPost *reusablePost = [list objectAtIndex:index];
        reusablePost.uid = post.uid;
        reusablePost.title = post.title;
        [reusablePost.textStorage setAttributedString:post.content];
        reusablePost.meta = post.meta;
        reusablePost.contents = nil;
        
        index = index + 1;
    }
    
    self.rows = self.rows + index;
    
    return index;
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
}


- (void)loadBackward {
    if (self.loading) {
        return;
    }
    if (self.from == 0) {
        self.countA = 0;
        [self loadListFrom:self.from to:BUCPostListUnitLength];
        return;
    }
    
    NSInteger from = self.from - BUCPostListUnitLength;
    if (from < 0) {
        from = 0;
    }
    NSUInteger to = self.from;
    [self loadListFrom:from to:to];
}


- (void)loadForward {
    if (self.loading) {
        return;
    }
    
    NSUInteger from = self.to;
    NSUInteger to = from + BUCPostListUnitLength;
    [self loadListFrom:from to:to];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.loading) {
        return;
    }
    UIImageView *topArrow = self.topRotateArrow;
    if (scrollView.contentOffset.y <= -60.0f) {
        [UIView animateWithDuration:0.2 animations:^{
            topArrow.transform = CGAffineTransformIdentity;
        }];
        if (self.from == 0) {
            self.topLoadingLabel.text = @"松开后刷新";
        } else {
            self.topLoadingLabel.text = @"松开后向前加载";
        }

    } else {
        [UIView animateWithDuration:0.2 animations:^{
            topArrow.transform = CGAffineTransformMakeRotation(M_PI);
        }];
        self.topLoadingLabel.text = @"向下拉动";
    }
    
    CGFloat y = scrollView.contentSize.height - CGRectGetHeight(self.tableView.bounds) + 60.0f;

    UIImageView *bottomArrow = self.bottomRotateArrow;
    if (scrollView.contentOffset.y >= y) {
        [UIView animateWithDuration:0.2 animations:^{
            bottomArrow.transform = CGAffineTransformMakeRotation(M_PI);
        }];

        self.bottomLoadingLabel.text = @"松开后向后加载";
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            bottomArrow.transform = CGAffineTransformIdentity;
        }];
        self.bottomLoadingLabel.text = @"向上拉动";
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.contentOffset.y <= - 60.0f) {
        self.topRotateArrow.hidden = YES;
        [self.topLoadingIndicator startAnimating];
        scrollView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
        self.topLoadingLabel.text = @"加载中，请等待...";
        [self loadBackward];
    } else if (self.fid && scrollView.contentOffset.y >= scrollView.contentSize.height - CGRectGetHeight(self.tableView.bounds) + 60.0f) {
        self.bottomRotateArrow.hidden = YES;
        [self.bottomLoadingIndicator startAnimating];
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 60, 0);
        self.bottomLoadingLabel.text = @"加载中，请等待...";
        [self loadForward];
    }
}


#pragma mark - table view data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.rows;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


#pragma mark - update views
- (void)updateTitle {
    if (self.fid) {
        unsigned long from = self.from + 1;
        unsigned long to = self.from + self.rows;

        self.navigationItem.title = [NSString stringWithFormat:@"%@[%lu-%lu]", self.fname, from, to];
    } else {
        self.navigationItem.title = self.fname;
    }
}


- (CGFloat)cellHeightWithPost:(BUCPost *)post {
    post.textContainer.size = CGSizeMake(self.contentWidth, FLT_MAX);
    [post.layoutManager ensureLayoutForTextContainer:post.textContainer];
    CGRect frame = [post.layoutManager usedRectForTextContainer:post.textContainer];
    frame.size.height = ceilf(frame.size.height);
    post.textFrame = frame;
    return BUCDefaultMargin * 3 + frame.size.height + self.metaLineHeight;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPost *post;
    if (indexPath.section < BUCPostListUnitLength) {
        post = [self.postListA objectAtIndex:indexPath.section];
    } else {
        post = [self.postListB objectAtIndex:indexPath.section - BUCPostListUnitLength];
    }

    if (post.contents.size.width != self.screenWidth) {
        post.cellHeight = [self cellHeightWithPost:post];
    } else {
        return post.cellHeight;
    }
    
    return post.cellHeight;
}


- (UIImage *)renderPost:(BUCPost *)post {
    UIImage *output;
    CGFloat mainHeight = post.textFrame.size.height;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.screenWidth, post.cellHeight), NO, 0);
    [post.layoutManager drawGlyphsForGlyphRange:NSMakeRange(0, post.textStorage.length) atPoint:CGPointMake(BUCDefaultPadding, BUCDefaultMargin)];
    [post.meta drawAtPoint:CGPointMake(BUCDefaultPadding, BUCDefaultMargin + mainHeight + BUCDefaultMargin)];
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = 0.25f;
    [[UIColor darkGrayColor] setStroke];
    [path moveToPoint:CGPointMake(0, mainHeight + BUCDefaultMargin + 2.0f)];
    [path addLineToPoint:CGPointMake(self.screenWidth, mainHeight + BUCDefaultMargin + 2.0f)];
    [path stroke];
    output = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return output;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPostListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    BUCPost *post;
    if (indexPath.section < BUCPostListUnitLength) {
        post = [self.postListA objectAtIndex:indexPath.section];
    } else {
        post = [self.postListB objectAtIndex:indexPath.section - BUCPostListUnitLength];
    }
    if (!post.contents || post.content.size.width != self.screenWidth) {
        post.contents = [self renderPost:post];
    }
    cell.contents.image = post.contents;
    
    return cell;
}


#pragma mark - navigation
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"postListToPostDetail" sender:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"postListToPostDetail"]) {
        BUCPostDetailController *postDetail = (BUCPostDetailController *)segue.destinationViewController;
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        if (indexPath.section < BUCPostListUnitLength) {
            postDetail.post = [self.postListA objectAtIndex:indexPath.section];
        } else {
            postDetail.post = [self.postListB objectAtIndex:indexPath.section];
        }
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
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

















