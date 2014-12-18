#import "BUCPostDetailController.h"
#import "BUCDataManager.h"
#import "BUCModels.h"
#import "BUCImageController.h"
#import "BUCTextStack.h"
#import "BUCPostListCell.h"
#import "BUCAppDelegate.h"
#import "BUCNewPostController.h"


@interface BUCPostDetailController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (nonatomic) BUCAppDelegate *appDelegate;

@property (nonatomic) NSMutableArray *postList;
@property (nonatomic) NSMutableSet *pidSet;
@property (nonatomic) NSMutableArray *opList;
@property (nonatomic) NSMutableIndexSet *opIndexSet;
@property (nonatomic) NSMutableArray *insertIndexPaths;
@property (nonatomic) NSUInteger from;
@property (nonatomic) NSUInteger to;
@property (nonatomic) NSUInteger rowCount;
@property (nonatomic) NSUInteger filterRowCount;
@property (nonatomic) NSUInteger postCount;
@property (nonatomic) NSUInteger pageCount;
@property (nonatomic) NSUInteger currentPage;

@property (nonatomic) CGFloat screenWidth;
@property (nonatomic) CGFloat contentWidth;
@property (nonatomic) CGFloat nativeWidth;
@property (nonatomic) CGFloat nativeHeight;
@property (nonatomic) CGFloat metaLineHeight;

@property (nonatomic) UIImage *defaultAvatar;
@property (nonatomic) UIImage *defaultImage;
@property (nonatomic) NSDictionary *metaAttribute;
@property (nonatomic) NSAttributedString *opTag;

@property (nonatomic) BOOL menuWasShown;
@property (nonatomic) BOOL flush;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL opOnly;
@property (nonatomic) BOOL reverse;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *menuPosition;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *replyButton;
@property (weak, nonatomic) IBOutlet UIView *menu;
@property (weak, nonatomic) IBOutlet UIButton *descend;
@property (weak, nonatomic) IBOutlet UIButton *user;
@property (weak, nonatomic) IBOutlet UIButton *star;
@property (weak, nonatomic) IBOutlet UITextField *pageInput;
@property (weak, nonatomic) IBOutlet UILabel *pageInfo;
@property (strong, nonatomic) IBOutlet UIView *pagePicker;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pageInputBottomSpace;

@property (weak, nonatomic) IBOutlet UIView *topLoadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *topLoadingIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *topRotateArrow;
@property (weak, nonatomic) IBOutlet UILabel *topLoadingLabel;

@property (weak, nonatomic) IBOutlet UIView *bottomLoadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *bottomLoadingIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *bottomRotateArrow;
@property (weak, nonatomic) IBOutlet UILabel *bottomLoadingLabel;


@end

static NSUInteger const BUCAPIMaxLoadRowCount = 20;
static NSUInteger const BUCPostPageMaxRowCount = 40;

@implementation BUCPostDetailController
#pragma mark - setup
- (void)dealloc {
    [self.appDelegate hideLoading];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"memory warning");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    [self dismissPageSelection];
    [self.appDelegate hideLoading];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textStyleChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShown:) name:UIKeyboardWillShowNotification object:nil];
}


- (void)setupRenderDefalut {
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
    
    UIFont *metaFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.metaAttribute = @{NSFontAttributeName:metaFont};
    self.opTag = [[NSAttributedString alloc] initWithString:@" [楼主]" attributes:@{NSFontAttributeName:metaFont, NSForegroundColorAttributeName:self.view.tintColor}];
    self.metaLineHeight = ceilf(metaFont.lineHeight);
    
    self.defaultAvatar = [UIImage imageNamed:@"avatar"];
    self.defaultImage = [UIImage imageNamed:@"loading"];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textStyleChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    NSMutableArray *barButtons = [self.navigationItem.rightBarButtonItems mutableCopy];
    [barButtons addObject:self.replyButton];
    self.title = self.rootPost.title;
    self.navigationItem.rightBarButtonItems = barButtons;
    self.topRotateArrow.transform = CGAffineTransformMakeRotation(M_PI);

    self.appDelegate = (BUCAppDelegate *)[UIApplication sharedApplication].delegate;
    self.postList = [[NSMutableArray alloc] init];
    self.pidSet = [[NSMutableSet alloc] init];
    self.opList = [[NSMutableArray alloc] init];
    self.opIndexSet = [[NSMutableIndexSet alloc] init];
    self.insertIndexPaths = [[NSMutableArray alloc] init];
    
    [self setupRenderDefalut];
    
    [self.appDelegate displayLoading];
    [self refreshFrom:self.from];
}


- (void)textStyleChanged:(NSNotification *)notification {
    [self.appDelegate displayLoading];
    UIFont *metaFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.metaAttribute = @{NSFontAttributeName:metaFont};
    self.opTag = [[NSAttributedString alloc] initWithString:@" [楼主]" attributes:@{NSFontAttributeName:metaFont, NSForegroundColorAttributeName:self.view.tintColor}];
    self.metaLineHeight = ceilf(metaFont.lineHeight);

    [self refreshFrom:self.from];
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


#pragma mark - list data management
- (void)buildList:(NSArray *)list {
    if (!self.flush) {
        [self.insertIndexPaths removeAllObjects];
    } else {
        [self.pidSet removeAllObjects];
        [self.opList removeAllObjects];
        self.rowCount = 0;
    }
    
    NSUInteger index = self.rowCount;
    NSUInteger count = self.postList.count;
    
    for (BUCPost *post in list) {
        if ([self.pidSet containsObject:post.pid]) {
            continue;
        }
        
        [self.pidSet addObject:post.pid];
        
        BUCPost *reusablePost;
        if (count <= index) {
            reusablePost = [[BUCPost alloc] initWithTextStack];
            [self.postList addObject:reusablePost];
        } else {
            reusablePost = [self.postList objectAtIndex:index];
        }
        [reusablePost.textStorage setAttributedString:post.content];
        reusablePost.user = post.user;
        reusablePost.index = index + self.from;
        reusablePost.avatarUrl = post.avatarUrl;
        if (post.avatarUrl) {
            BUCPostDetailController * __weak weakSelf = self;
            [[BUCDataManager sharedInstance]
             getImageWithUrl:post.avatarUrl size:CGSizeMake(40.0f, 40.0f) onSuccess:^(UIImage *image) {
                 reusablePost.avatar = image;
                 if (reusablePost.contents) {
                     reusablePost.contents = [weakSelf drawAvatarWith:reusablePost];
                     NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                     if ([weakSelf.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                         BUCPostListCell *cell = (BUCPostListCell *)[weakSelf.tableView cellForRowAtIndexPath:indexPath];
                         cell.contents.image = reusablePost.contents;
                     }
                 }
             }];
        }
        reusablePost.date = post.date;
        reusablePost.contents = nil;
        if (!self.flush) {
            [self.insertIndexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
        
        if ([self.rootPost.uid isEqualToString:post.uid]) {
            [self.opIndexSet addIndex:index];
            [self.opList addObject:reusablePost];
        }
        
        index = index + 1;
    }
    
    self.rowCount = index;
    if (self.opOnly) {
        self.filterRowCount = self.opList.count;
    } else {
        self.filterRowCount = self.rowCount;
    }
}


- (void)loadListFrom:(NSUInteger)from {
    BUCPostDetailController * __weak weakSelf = self;
    NSUInteger to = from + BUCAPIMaxLoadRowCount;
    [[BUCDataManager sharedInstance]
     listOfPost:self.rootPost.tid
     
     from:[NSString stringWithFormat:@"%lu", (unsigned long)from]
     
     to:[NSString stringWithFormat:@"%lu", (unsigned long)to]
     
     onSuccess:^(NSArray *list) {
         if (weakSelf.flush) {
             weakSelf.from = from;
         }
         if (from == 0) {
             weakSelf.rootPost.uid = ((BUCPost *)[list objectAtIndex:from]).uid;
         }
         weakSelf.to = to;
         [weakSelf buildList:list];
         if (weakSelf.flush || weakSelf.reverse) {
             [weakSelf.tableView setContentOffset:CGPointZero];
             [weakSelf.tableView reloadData];
         } else {
             [weakSelf.tableView insertRowsAtIndexPaths:weakSelf.insertIndexPaths withRowAnimation:UITableViewRowAnimationNone];
         }
         
         [weakSelf endLoading];
     }
     
     onError:^(NSString *errorMsg) {
         [weakSelf endLoading];
         [weakSelf.appDelegate alertWithMessage:errorMsg];
     }];
}


- (void)refreshFrom:(NSInteger)from {
    self.loading = YES;
    self.flush = YES;
    
    BUCPostDetailController * __weak weakSelf = self;
    [[BUCDataManager sharedInstance]
     childCountOfForum:nil
     thread:self.rootPost.tid
     
     onSuccess:^(NSUInteger count) {
         weakSelf.postCount = count + 1;
         weakSelf.pageCount = [weakSelf pageCountWithPostCount:weakSelf.postCount];
         [weakSelf loadListFrom:from];
     }
     
     onError:^(NSString *errorMsg) {
         [weakSelf endLoading];
         [weakSelf.appDelegate alertWithMessage:errorMsg];
     }];
}


- (void)loadMore {
    self.flush = NO;
    self.loading = YES;
    if (self.reverse) {
        self.topRotateArrow.hidden = YES;
        [self.topLoadingIndicator startAnimating];
        self.tableView.contentInset = UIEdgeInsetsMake(50.0f, 0.0f, 0.0f, 0.0f);
        self.topLoadingLabel.text = @"加载中，请等待...";
    } else {
        self.bottomRotateArrow.hidden = YES;
        [self.bottomLoadingIndicator startAnimating];
        self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 50.0f, 0.0f);
        self.bottomLoadingLabel.text = @"加载中，请等待...";
    }
    [self loadListFrom:self.to];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.loading) {
        return;
    }
    
    UIImageView *topArrow = self.topRotateArrow;
    UIImageView *bottomArrow = self.bottomRotateArrow;
    CGFloat maxOffset = scrollView.contentSize.height - CGRectGetHeight(self.tableView.bounds);
    if ((self.reverse && scrollView.contentOffset.y <= -50.0f) ||
        (!self.reverse && scrollView.contentOffset.y >= maxOffset + 50.0f)) {
        if (self.reverse) {
            [UIView animateWithDuration:0.2 animations:^{
                topArrow.transform = CGAffineTransformIdentity;
            }];
            self.topLoadingLabel.text = @"松开后加载更多";
        } else {
            [UIView animateWithDuration:0.2 animations:^{
                bottomArrow.transform = CGAffineTransformMakeRotation(M_PI);
            }];
            self.bottomLoadingLabel.text = @"松开后加载更多";
        }
    } else if ((self.reverse && scrollView.contentOffset.y < 0.0f) ||
               (!self.reverse && scrollView.contentOffset.y > maxOffset)) {
        if (self.reverse) {
            [UIView animateWithDuration:0.2 animations:^{
                topArrow.transform = CGAffineTransformMakeRotation(M_PI);
            }];
            self.topLoadingLabel.text = @"向下拉动";
        } else {
            [UIView animateWithDuration:0.2 animations:^{
                bottomArrow.transform = CGAffineTransformIdentity;
            }];
            self.bottomLoadingLabel.text = @"向上拉动";
        }
    }
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.loading) {
        return;
    } else if ((self.reverse && scrollView.contentOffset.y <= - 50.0f) ||
               (!self.reverse && scrollView.contentOffset.y >= scrollView.contentSize.height - CGRectGetHeight(self.tableView.bounds) + 50.0f)) {
        scrollView.bounces = NO;
        [self loadMore];
    }
}


- (void)endLoading {
    [self.appDelegate hideLoading];
    self.tableView.contentInset = UIEdgeInsetsZero;
    if (self.reverse) {
        self.topLoadingView.hidden = NO;
    } else {
        self.bottomLoadingView.hidden = NO;
    }
    self.topRotateArrow.hidden = NO;
    self.bottomRotateArrow.hidden = NO;
    [self.topLoadingIndicator stopAnimating];
    [self.bottomLoadingIndicator stopAnimating];
    self.topLoadingLabel.text = @"向下拉动";
    self.bottomLoadingLabel.text = @"向上拉动";
    self.loading = NO;
    self.tableView.bounces = YES;
    self.currentPage = self.to / BUCPostPageMaxRowCount + 1;
    self.navigationItem.titleView = nil;
}


- (NSUInteger)pageCountWithPostCount:(NSUInteger)postCount {
    NSUInteger pageCount = 0;
    for (NSUInteger count = 0; count < postCount; count = count + 40) {
        pageCount = pageCount + 1;
    }
    
    return pageCount;
}


#pragma mark - table view update
- (BUCPost *)getPostWithIndexpath:(NSIndexPath *)indexPath {
    NSArray *list;
    if (self.opOnly) {
        list = self.opList;
    } else {
        list = self.postList;
    }
    
    NSUInteger index;
    if (self.reverse) {
        index = self.filterRowCount - 1 - indexPath.row;
    } else {
        index = indexPath.row;
    }
    
    return [list objectAtIndex:index];
}


- (CGFloat)cellHeightWithPost:(BUCPost *)post {
    post.textContainer.size = CGSizeMake(self.contentWidth, FLT_MAX);
    [post.layoutManager ensureLayoutForTextContainer:post.textContainer];
    CGRect frame = [post.layoutManager usedRectForTextContainer:post.textContainer];
    frame.size.height = ceilf(frame.size.height);
    post.textFrame = frame;
    return BUCDefaultMargin * 2 + frame.size.height + 40.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPost *post = [self getPostWithIndexpath:indexPath];
    
    if (post.contents.size.width != self.screenWidth) {
        post.cellHeight = [self cellHeightWithPost:post];
    }
    
    return post.cellHeight;
}


- (UIImage *)renderPost:(BUCPost *)post inRect:(CGRect)rect {
    UIImage *output;
    
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0.0f);
    [[UIColor whiteColor] setFill];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
    [path fill];
    
    if (post.avatar) {
        [post.avatar drawAtPoint:CGPointMake(BUCDefaultPadding, BUCDefaultMargin)];
        post.avatar = nil;
    } else {
        [self.defaultAvatar drawAtPoint:CGPointMake(BUCDefaultPadding, BUCDefaultMargin)];
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    NSMutableAttributedString *user = [[NSMutableAttributedString alloc] initWithString:post.user attributes:self.metaAttribute];
    if ([self.opIndexSet containsIndex:post.index]) {
        [user appendAttributedString:self.opTag];
    }
    [user drawAtPoint:CGPointMake(45.0f + BUCDefaultPadding, BUCDefaultMargin)];
    CGContextRestoreGState(context);
    
    NSAttributedString *index = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu楼", (unsigned long)post.index + 1] attributes:self.metaAttribute];
    [index drawAtPoint:CGPointMake(self.screenWidth - BUCDefaultMargin - ceilf([index boundingRectWithSize:CGSizeMake(FLT_MAX, FLT_MAX) options:0 context:nil].size.width), BUCDefaultMargin)];
    
    NSAttributedString *date = [[NSAttributedString alloc] initWithString:post.date attributes:self.metaAttribute];
    [date drawAtPoint:CGPointMake(45.0f + BUCDefaultPadding, BUCDefaultMargin * 2.0f + self.metaLineHeight)];
    
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), BUCDefaultPadding, BUCDefaultMargin + 40.0f);
    [post.layoutManager drawBackgroundForGlyphRange:NSMakeRange(0.0f, post.textStorage.length) atPoint:CGPointZero];
    [post.layoutManager drawGlyphsForGlyphRange:NSMakeRange(0.0f, post.textStorage.length) atPoint:CGPointZero];
    output = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return output;
}


- (UIImage *)drawAvatarWith:(BUCPost *)post {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.screenWidth, post.cellHeight), YES, 0.0f);
    [post.contents drawAtPoint:CGPointZero];
    CGRect frame = CGRectMake(BUCDefaultPadding, BUCDefaultMargin, 40.0f, 40.0f);
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:frame];
    [[UIColor whiteColor] setFill];
    [path fill];
    [post.avatar drawAtPoint:frame.origin];
//    post.avatar = nil;
    UIImage *output = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return output;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPostListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    BUCPost *post = [self getPostWithIndexpath:indexPath];
    
    if (post.contents.size.width != self.screenWidth) {
        post.contents = [self renderPost:post inRect:cell.bounds];
    }
    
    if (post.avatar) {
        post.contents = [self drawAvatarWith:post];
    }
    cell.contents.image = post.contents;
    
    if (!self.reverse && indexPath.row == self.filterRowCount - 1 && !self.loading && self.to < self.postCount) {
        [self loadMore];
    }
    
    return cell;
}


#pragma mark - actions
- (IBAction)toggleMenu {
    if (self.loading) {
        return;
    }
    [self dismissPageSelection];
    BUCPostDetailController * __weak weakSelf = self;
    [weakSelf.view layoutIfNeeded];
    if (self.menuPosition.constant == 0) {
        self.menuPosition.constant = -200;
        self.menuWasShown = NO;
        self.tableView.userInteractionEnabled = YES;
    } else {
        self.menuPosition.constant = 0;
        self.menuWasShown = YES;
        self.tableView.userInteractionEnabled = NO;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        [weakSelf.view layoutIfNeeded];
    }];
}


- (IBAction)dismissMenu:(UIGestureRecognizer *)sender {
    CGPoint location = [sender locationInView:self.menu];
    if ([self.menu pointInside:location withEvent:nil]) {
        return;
    } else if (self.menuWasShown) {
        [self toggleMenu];
    }
}


- (IBAction)bookmark:(id)sender {

    [self toggleMenu];
}


#pragma mark - managing keyboard
- (IBAction)showPageInput {
    [self toggleMenu];
    self.pageInfo.text = [NSString stringWithFormat:@"当前%ld/%ld页", (unsigned long)self.currentPage, (unsigned long)self.pageCount];
    self.tableView.userInteractionEnabled = NO;
    [self.pageInput becomeFirstResponder];
}


- (void)keyboardWillShown:(NSNotification *)notification {
    if (![self.pageInput isFirstResponder]) {
        return;
    }
    NSDictionary *info = notification.userInfo;
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.pageInputBottomSpace.constant = kbSize.height;
    self.tableView.userInteractionEnabled = NO;
    self.pageInfo.text = [NSString stringWithFormat:@"当前%ld/%ld页", (unsigned long)self.currentPage, (unsigned long)self.pageCount];
}


- (IBAction)dismissPageSelection {
    [self.pageInput resignFirstResponder];
    self.tableView.userInteractionEnabled = YES;
    self.pageInput.text = @"";
    self.pageInputBottomSpace.constant = - 50.0f;
}


#pragma mark - list manipulation
- (IBAction)donePageSelection {
    NSString *page = self.pageInput.text;
    if (page.length == 0) {
        [self.appDelegate alertWithMessage:@"请输入页数"];
        return;
    }
    
    NSUInteger pageNumber = [self validPageNumber:page];
    if (pageNumber == 0) {
        [self.appDelegate alertWithMessage:@"页面数据错误，请重新输入"];
        return;
    }
    
    NSInteger from = (pageNumber - 1) * BUCPostPageMaxRowCount;
    [self dismissPageSelection];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [indicator startAnimating];
    self.navigationItem.titleView = indicator;
    [self refreshFrom:from];
}


- (NSUInteger)validPageNumber:(NSString *)page {
    NSUInteger pageNumber = page.integerValue;
    if (pageNumber <= 0 || pageNumber > self.pageCount) {
        return 0;
    }
    
    return pageNumber;
}


- (IBAction)opFilter:(id)sender {
    self.opOnly = !self.opOnly;
    self.user.selected = self.opOnly;
    [self toggleMenu];
    if (self.opOnly) {
        self.filterRowCount = self.opList.count;
    } else {
        self.filterRowCount = self.rowCount;
    }
    [self.tableView setContentOffset:CGPointZero];
    [self.tableView reloadData];
}


- (IBAction)reverse:(id)sender {
    self.reverse = !self.reverse;
    self.descend.selected = self.reverse;
    self.topLoadingView.hidden = !self.topLoadingView.hidden;
    self.bottomLoadingView.hidden = !self.bottomLoadingView.hidden;
    [self toggleMenu];
    [self.tableView setContentOffset:CGPointZero];
    [self.tableView reloadData];
}


#pragma mark - table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filterRowCount;
}


#pragma mark - navigation
- (IBAction)reply {
    [self performSegueWithIdentifier:@"postDetailToNewPost" sender:nil];
}


- (IBAction)unwindToPostDetail:(UIStoryboardSegue *)segue {

}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"postDetailToNewPost"]) {
        BUCNewPostController *newPost = (BUCNewPostController *)(((UINavigationController *)segue.destinationViewController).topViewController);
        newPost.tid = self.rootPost.tid;
        newPost.parentTitle = self.rootPost.title;
        newPost.forumName = self.rootPost.forumName.string;
        newPost.unwindIdentifier = @"newPostToPostDetail";
    }
}


- (void)imageTapHandler:(BUCImageAttachment *)attachment {
    BUCImageController *imageController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BUCImageController"];
    imageController.url = attachment.url;
    [self presentViewController:imageController animated:YES completion:nil];
}


@end



















