#import "BUCPostDetailController.h"
#import "BUCDataManager.h"
#import "BUCModels.h"
#import "BUCImageController.h"
#import "BUCTextStack.h"
#import "BUCPostDetailCell.h"
#import "BUCAppDelegate.h"
#import "BUCNewPostController.h"


@interface BUCPostDetailController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (nonatomic) NSString *postTitle;

@property (nonatomic) NSMutableArray *postList;

@property (nonatomic) NSMutableArray *bookmarkList;
@property (nonatomic) NSString *bookmarkListPath;
@property (nonatomic) NSInteger bookmarkIndex;

@property (nonatomic) NSUInteger from;
@property (nonatomic) NSUInteger to;
@property (nonatomic) NSUInteger postCount;
@property (nonatomic) NSUInteger pageCount;
@property (nonatomic) NSUInteger currentPage;

@property (nonatomic) BOOL flush;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL opOnly;
@property (nonatomic) BOOL reverse;

@property (nonatomic) BOOL newReply;

@property (nonatomic) UIImage *defaultAvatar;
@property (nonatomic) UIImage *defaultImage;

@property (nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *menuPosition;

@property (weak, nonatomic) IBOutlet UILabel *footLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingMoreIndicator;

@property (weak, nonatomic) IBOutlet UIView *menu;
@property (weak, nonatomic) IBOutlet UIButton *descend;
@property (weak, nonatomic) IBOutlet UIButton *user;
@property (weak, nonatomic) IBOutlet UIButton *star;

@property (weak, nonatomic) IBOutlet UITextField *pageInput;
@property (weak, nonatomic) IBOutlet UILabel *pageInfo;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pageInputBottomSpace;

@property (nonatomic) BUCAppDelegate *appDelegate;

@end


static NSUInteger const BUCPostDetailMinListLength = 20;


@implementation BUCPostDetailController
#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.from = 0;
    self.to = 20;
    self.opOnly = NO;
    self.reverse = NO;
    
    self.defaultAvatar = [UIImage imageNamed:@"avatar"];
    self.defaultImage = [UIImage imageNamed:@"loading"];
    
    self.bookmarkListPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:@"/BUCBookmarkList.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.bookmarkListPath]) {
        self.bookmarkList = [NSMutableArray arrayWithContentsOfFile:self.bookmarkListPath];
    }
    
    if (self.bookmarkList && self.bookmarkList.count > 0 && !self.post.bookmarked) {
        NSInteger index = 0;
        for (NSDictionary *bookmark in self.bookmarkList) {
            NSString *tid = [bookmark objectForKey:@"tid"];
            if ([tid isEqualToString:self.post.tid]) {
                self.post.bookmarked = YES;
                self.post.bookmarkIndex = index;
                break;
            }
            index = index + 1;
        }
    }
    self.star.selected = self.post.bookmarked;
    
    NSString *title = self.post.title.string;
    if (title.length > 5) {
        self.postTitle = [NSString stringWithFormat:@"%@...", [title substringToIndex:5]];
    } else {
        self.postTitle = title;
    }
    
    NSMutableArray *barButtons = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(reply)];
    [barButtons addObject:button];
    self.navigationItem.rightBarButtonItems = barButtons;
    
    
    
    self.appDelegate = [UIApplication sharedApplication].delegate;
    [self refreshFrom:self.from to:self.to];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    
    if (self.newReply) {
        [self reverse:nil];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self dismissPageSelection];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.loading) {
        [self.appDelegate hideLoading];
    }
}


#pragma mark - data management
- (void)refreshFrom:(NSInteger)from to:(NSInteger)to {
    if (self.loading) {
        return;
    }
    
    [self.appDelegate displayLoading];
    
    self.flush = YES;
    self.loading = YES;
    
    BUCPostDetailController * __weak weakSelf = self;
    [[BUCDataManager sharedInstance]
     childCountOfForum:nil
     thread:self.post.tid
     
     onSuccess:^(NSUInteger count) {
         NSUInteger postCount = count + 1;
         NSInteger newFrom = from;
         NSInteger newTo = to;
         if (weakSelf.reverse) {
             if (from == 0) {
                 newFrom = postCount - BUCPostDetailMinListLength;
                 newTo = postCount;
             } else {
                 newFrom = newFrom + postCount - weakSelf.postCount;
                 newTo = newTo + postCount - weakSelf.postCount;
             }

             if (newFrom < 0) {
                 newFrom = 0;
             }
         }
         [weakSelf loadListFrom:newFrom to:newTo postCount:postCount];
     }
     
     onError:^(NSError *error) {
         [weakSelf endLoading];
         [weakSelf.appDelegate alertWithMessage:error.localizedDescription];
     }];
}


- (IBAction)loadMore {
    [self.loadingMoreIndicator startAnimating];
    NSInteger from;
    NSInteger to;
    if (self.reverse) {
        from = self.from - BUCPostDetailMinListLength;
        if (from < 0) {
            from = 0;
        }
        to = self.from;
    } else {
        from = self.to;
        to = self.to + BUCPostDetailMinListLength;
    }

    [self loadListFrom:from to:to postCount:self.postCount];
}


- (void)loadListFrom:(NSUInteger)from to:(NSUInteger)to postCount:(NSUInteger)postCount {
    BUCPostDetailController * __weak weakSelf = self;
    self.loading = YES;
    [[BUCDataManager sharedInstance]
     listOfPost:self.post.tid
     
     from:[NSString stringWithFormat:@"%lu", (unsigned long)from]
     
     to:[NSString stringWithFormat:@"%lu", (unsigned long)to]
     
     onSuccess:^(NSArray *list) {
         [weakSelf updateNavigationStateWithFrom:from to:to postCount:postCount];
         [weakSelf buildList:list];
         [weakSelf updateUI];
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
        self.to = to;
        self.postCount = count;
        self.pageCount = [self pageCountWithPostCount:count];
    } else {
        if (self.reverse) {
            self.from = from;
        } else {
            self.to = to;
        }
    }
    
    if (self.reverse) {
        self.currentPage = (count - to) / 40 + 1;
    } else {
        self.currentPage = from / 40 + 1;
    }
}


- (void)updateUI {
    unsigned long from;
    unsigned long to;
    if (self.reverse) {
        from = self.to;
        to = self.from + 1;
    } else {
        from = self.from + 1;
        to = self.to;
        if (self.to >= self.postCount) {
            to = self.postCount;
        }
    }
    self.navigationItem.title = [NSString stringWithFormat:@"%@[%lu-%lu]", self.postTitle, from, to];
    
    if ((!self.reverse && self.to >= self.postCount) || (self.reverse && self.from == 0)) {
        self.footLabel.text = @"End of list";
        self.tableView.tableFooterView.userInteractionEnabled = NO;
    } else {
        self.tableView.tableFooterView.userInteractionEnabled = YES;
        self.footLabel.text = @"More...";
    }
    self.tableView.tableFooterView.hidden = NO;
}


- (void)buildList:(NSArray *)list {
    NSMutableArray *postList;
    NSMutableArray *insertRows;
    if (self.flush) {
        postList = [[NSMutableArray alloc] init];
        [self.tableView setContentOffset:CGPointZero];
    } else {
        postList = self.postList;
    }
    
    NSInteger index = postList.count;
    NSEnumerator *listEnumerator;
    if (self.reverse) {
        listEnumerator = [list reverseObjectEnumerator];
    } else {
        listEnumerator = [list objectEnumerator];
    }
    
    if (index == 0) {
        self.post.uid = ((BUCPost *)[list objectAtIndex:index]).uid;
    }
    
    for (BUCPost *post in listEnumerator) {
        if ((self.opOnly &&  ![post.uid isEqualToString:self.post.uid]) ||
            [self isLoadedBefore:post against:postList]) {
            continue;
        }
        
        if (self.reverse) {
            post.index = self.to - 1 - index;
        } else {
            post.index = self.from + index;
        }
        
        [postList addObject:post];
        
        if (!self.flush) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            if (!insertRows) {
                insertRows = [[NSMutableArray alloc] init];
            }
            [insertRows addObject:indexPath];
        }
        
        index = index + 1;
    }
    
    self.postList = postList;
    
    if (self.flush) {
        [self.tableView reloadData];
    } else if (insertRows && insertRows.count > 0) {
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:insertRows withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
}


- (void)endLoading {
    [self.appDelegate hideLoading];
    [self.loadingMoreIndicator stopAnimating];
    self.loading = NO;
    self.flush = NO;
}


- (NSUInteger)pageCountWithPostCount:(NSUInteger)postCount {
    NSUInteger pageCount = 0;
    for (NSUInteger count = 0; count < postCount; count = count + 40) {
        pageCount = pageCount + 1;
    }
    
    return pageCount;
}


#pragma mark - layout
- (void)calculateFrameOfPost:(BUCPost *)post {
    static NSTextStorage *textStorage;
    static BUCTextContainer *textContainer;
    static BUCLayoutManager *layoutManager;;
    static CGPoint contentOrigin;
    static dispatch_once_t onceSecurePredicate;
    
    CGFloat contentWidth = CGRectGetWidth(self.tableView.frame) - 2 * BUCDefaultMargin;
    dispatch_once(&onceSecurePredicate, ^{
        textStorage = [[NSTextStorage alloc] init];
        layoutManager = [[BUCLayoutManager alloc] init];
        [textStorage addLayoutManager:layoutManager];
        textContainer = [[BUCTextContainer alloc] initWithSize:CGSizeMake(contentWidth, FLT_MAX)];
        textContainer.lineFragmentPadding = 0;
        [layoutManager addTextContainer:textContainer];
        contentOrigin = CGPointMake(BUCDefaultMargin, 45.0f + BUCDefaultMargin);
    });
    
    textContainer.size = CGSizeMake(contentWidth, FLT_MAX);
    [textStorage setAttributedString:post.content];
    [layoutManager ensureLayoutForTextContainer:textContainer];
    CGRect frame = [layoutManager usedRectForTextContainer:textContainer];
    frame.size.width = contentWidth;
    frame.size.height = ceilf(frame.size.height) + BUCDefaultMargin + BUCDefaultPadding;
    frame.origin = contentOrigin;
    post.textFrame = frame;
    post.cellHeight = CGRectGetMaxY(frame);
}


- (void)configureCell:(BUCPostDetailCell *)cell post:(BUCPost *)post {
    cell.avatar.image = self.defaultAvatar;
    // avatar
    if (post.avatar) {
        [[BUCDataManager sharedInstance] getImageWithUrl:post.avatar size:cell.avatar.frame.size onSuccess:^(UIImage *image) {
            if (image) {
                cell.avatar.image = image;
            }
        }];
    }
    
    // username
    NSString *username = post.user;
    if ([post.user isEqualToString:self.post.user]) {
        username = [NSString stringWithFormat:@"%@(LZ)", post.user];
    }
    [cell.poster setTitle:username forState:UIControlStateNormal];
    
    // index
    cell.index.text = [NSString stringWithFormat:@"%ldL", (long)(post.index + 1)];
    
    // dateline
    cell.dateline.text = post.dateline;
    
    // content
    UITextView *textView;
    if (cell.content) {
        textView = cell.content;
        [textView.textStorage setAttributedString:post.content];
        textView.frame = post.textFrame;
    } else {
        textView = [self textViewWithRichText:post.content frame:post.textFrame];
        [cell.contentView addSubview:textView];
        cell.content = textView;
    }
    
    NSArray *attachmentList = [post.content attribute:BUCAttachmentListAttributeName atIndex:0 effectiveRange:NULL];
    if (attachmentList) {
        if (!cell.imageViewList) {
            cell.imageViewList = [[NSMutableArray alloc] init];
        }
        [self layoutImages:attachmentList textView:textView imageViewList:cell.imageViewList];
    }
}


- (void)layoutImages:(NSArray *)imageList textView:(UITextView *)textView imageViewList:(NSMutableArray *)imageViewList {
    CGFloat defaultWidth = CGRectGetWidth(self.tableView.frame) - 2 * BUCDefaultPadding - 2 * BUCDefaultMargin;
    for (BUCImageAttachment *attachment in imageList) {
        CGRect frame = [textView.layoutManager boundingRectForGlyphRange:NSMakeRange(attachment.glyphIndex, 1) inTextContainer:textView.textContainer];
        frame.origin.x = ceilf(frame.origin.x);
        frame.origin.y = ceilf(frame.origin.y);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
        imageView.opaque = YES;
        imageView.contentMode = UIViewContentModeCenter;
        imageView.image = self.defaultImage;
        [imageViewList addObject:imageView];
        [textView addSubview:imageView];
        
        if (attachment.path) {
            imageView.image = [[BUCDataManager sharedInstance] getImageWithPath:attachment.path];
        } else {
            frame.size.width = 100.0f;
            frame.origin.x = defaultWidth / 2 - 50.0f;
            [[BUCDataManager sharedInstance] getImageWithUrl:attachment.url size:attachment.bounds.size onSuccess:^(UIImage *image) {
                imageView.image = image;
                CGRect frame = imageView.frame;
                frame.size = image.size;
                frame.origin.x = defaultWidth / 2 - frame.size.width / 2;
                imageView.frame = frame;
            }];
        }
    }
}


- (UITextView *)textViewWithRichText:(NSAttributedString *)richText frame:(CGRect)textFrame {
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:richText];
    BUCLayoutManager *layoutManager = [[BUCLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    BUCTextContainer *textContainer = [[BUCTextContainer alloc] initWithSize:CGSizeMake(CGRectGetWidth(textFrame), FLT_MAX)];
    textContainer.lineFragmentPadding = 0;
    [layoutManager addTextContainer:textContainer];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:textFrame textContainer:textContainer];
    textView.textContainerInset = UIEdgeInsetsZero;
    textView.editable = NO;
    textView.scrollEnabled = NO;
    textView.selectable = NO;
    textView.opaque = YES;
    textView.backgroundColor = [UIColor whiteColor];
    
    return textView;
}


- (BOOL)isLoadedBefore:(BUCPost *)newpost against:(NSArray *)list{
    for (BUCPost *post in list) {
        if ([post.pid isEqualToString:newpost.pid]) {
            return YES;
        }
    }
    
    return NO;
}


#pragma mark - actions
- (IBAction)toggleMenu {
    if (self.loading) {
        return;
    }
    BUCPostDetailController * __weak weakSelf = self;
    [weakSelf.view layoutIfNeeded];
    if (self.menuPosition.constant == 0) {
        self.menuPosition.constant = -200;
    } else {
        self.menuPosition.constant = 0;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        [weakSelf.view layoutIfNeeded];
    }];
}


- (IBAction)bookmark:(id)sender {
    if (self.post.bookmarked) {
        self.post.bookmarked = NO;
        [self.bookmarkList removeObjectAtIndex:self.post.bookmarkIndex];
    } else {
        self.post.bookmarked = YES;
        self.post.bookmarkIndex = self.bookmarkList.count;
        NSDictionary *post = @{@"tid":self.post.tid, @"title":self.post.title.string};
        if (!self.bookmarkList) {
            self.bookmarkList  = [[NSMutableArray alloc] init];
        }
        [self.bookmarkList addObject:post];
    }
    [self.bookmarkList writeToFile:self.bookmarkListPath atomically:YES];
    
    self.star.selected = !self.star.selected;
    [self toggleMenu];
}


#pragma mark - managing keyboard
- (IBAction)showPageInput {
    [self.pageInput becomeFirstResponder];
    [self toggleMenu];
}


- (IBAction)dismissPageSelection {
    [self.pageInput resignFirstResponder];
    self.pageInputBottomSpace.constant = -50.0f;
    self.tableView.userInteractionEnabled = YES;
    self.pageInput.text = @"";
}


- (void)keyboardWasShown:(NSNotification *)notification {
    if (![self.pageInput isFirstResponder]) {
        return;
    }
    NSDictionary *info = notification.userInfo;
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.pageInputBottomSpace.constant = kbSize.height;
    self.tableView.userInteractionEnabled = NO;
    self.pageInfo.text = [NSString stringWithFormat:@"当前%ld/%ld页", (unsigned long)self.currentPage, (unsigned long)self.pageCount];
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
        [self.appDelegate alertWithMessage:@"页数无效，请重新输入"];
        return;
    }
    
    NSInteger from = (pageNumber - 1) * 40;
    NSInteger to = from + BUCPostDetailMinListLength;
    if (self.reverse) {
        to = self.postCount - from;
        from = to - BUCPostDetailMinListLength;
        if (from < 0) {
            from = 0;
        }
    }
    [self dismissPageSelection];
    self.opOnly = NO;
    self.user.selected = NO;
    [self refreshFrom:from to:to];
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
    self.reverse = NO;
    self.descend.selected = NO;
    UIButton *button = (UIButton *)sender;
    button.selected = self.opOnly;
    
    [self toggleMenu];
    [self refreshFrom:0 to:BUCPostDetailMinListLength];
}


- (IBAction)reverse:(id)sender {
    self.reverse = !self.reverse;
    self.opOnly = NO;
    self.user.selected = NO;
    self.descend.selected = self.reverse;
    
    if (!self.newReply) {
        [self toggleMenu];
    }
    [self refreshFrom:0 to:BUCPostDetailMinListLength];
}


#pragma mark - table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.postList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPostDetailCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    [self configureCell:cell post:[self.postList objectAtIndex:indexPath.row]];
    
    if (!self.loading && indexPath.row == self.postList.count - 1 &&
        ((self.reverse && self.from > 0) || (!self.reverse && self.postCount > self.to))) {
        [self loadMore];
    }

    return cell;
}


#pragma mark - table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPost *post = (BUCPost *)[self.postList objectAtIndex:indexPath.row];

    if (post.cellHeight > 0) {
        return post.cellHeight;
    } else {
        [self calculateFrameOfPost:post];
    }
    
    return post.cellHeight;
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        
    }
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

}


#pragma mark - navigation
- (void)reply {
    [self performSegueWithIdentifier:@"postDetailToNewPost" sender:nil];
}


- (IBAction)unwindToPostDetail:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"newPostToPostDetail"]) {
        self.newReply = YES;
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"postDetailToNewPost"]) {
        BUCNewPostController *newPost = (BUCNewPostController *)(((UINavigationController *)segue.destinationViewController).topViewController);
        newPost.tid = self.post.tid;
        newPost.parentTitle = self.post.title.string;
        newPost.forumName = self.post.forumName;
        newPost.unwindIdentifier = @"newPostToPostDetail";
    }
}


- (void)imageTapHandler:(BUCImageAttachment *)attachment {
    BUCImageController *imageController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BUCImageController"];
    imageController.url = attachment.url;
    [self presentViewController:imageController animated:YES completion:nil];
}


@end



















