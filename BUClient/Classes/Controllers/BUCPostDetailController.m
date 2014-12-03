#import "BUCPostDetailController.h"
#import "BUCDataManager.h"
#import "BUCModels.h"
#import "BUCImageController.h"
#import "BUCTextStack.h"
#import "BUCPostDetailCell.h"


@interface BUCPostDetailController () <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSMutableArray *postList;

@property (nonatomic) NSString *from;
@property (nonatomic) NSString *to;

@property (nonatomic) NSUInteger postCount;
@property (nonatomic) NSUInteger location;
@property (nonatomic) NSUInteger length;

@property (nonatomic) BOOL isRefresh;

@property (nonatomic) UIImage *defaultAvatar;

@end


static NSUInteger const BUCPostDetailMinPostCount = 20;


@implementation BUCPostDetailController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.from = @"0";
    self.to = @"20";
    
    if ([self.tableView respondsToSelector:@selector(layoutMargins)]) {
        self.tableView.layoutMargins = UIEdgeInsetsZero;
    }
    
    self.defaultAvatar = [UIImage imageNamed:@"avatar"];
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self refresh];
}


- (void)imageTapHandler:(BUCImageAttachment *)attachment {
    BUCImageController *imageController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BUCImageController"];
    imageController.url = attachment.url;
    [self presentViewController:imageController animated:YES completion:nil];
}


- (void)refresh {
    [self displayLoading];
    
    self.isRefresh = YES;

    BUCPostDetailController * __weak weakSelf = self;
    [[BUCDataManager sharedInstance]
     childCountOfForum:nil
     post:self.post.tid
     onSuccess:^(NSUInteger count) {
         weakSelf.postCount = count;
         [weakSelf loadList];
     } onError:^(NSError *error) {
         [weakSelf hideLoading];
         [weakSelf alertMessage:error.localizedDescription];
     }];
}


- (void)loadList {
    BUCPostDetailController * __weak weakSelf = self;
    
    [[BUCDataManager sharedInstance]
     listOfPost:self.post.tid
     
     from:self.from
     
     to:self.to
     
     onSuccess:^(NSArray *list) {
         NSUInteger from = weakSelf.from.integerValue;
         if (weakSelf.isRefresh) {
             weakSelf.location = from;
             weakSelf.length = BUCPostDetailMinPostCount;
         } else {
             weakSelf.length = weakSelf.length + BUCPostDetailMinPostCount;
         }
         
         [weakSelf buildList:list];
         [weakSelf hideLoading];
     }
     
     onError:^(NSError *error) {
         [weakSelf hideLoading];
         [weakSelf alertMessage:error.localizedDescription];
     }];
}


- (void)loadMore {
    
}


- (void)jumpPage {
    
}


- (IBAction)jumpToPoster:(id)sender {
}


#pragma mark - table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.postList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * const cellIdentifier = @"cell";
    BUCPostDetailCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell post:[self.postList objectAtIndex:indexPath.row]];

    return cell;
}


#pragma mark - table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = ((BUCPost *)[self.postList objectAtIndex:indexPath.row]).cellHeight;
    return height;
}


#pragma mark - scroll view delegate
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//    
//}

#pragma mark - private methods
- (void)buildList:(NSArray *)list {
    NSMutableArray *postList;
    if (self.isRefresh) {
        postList = [[NSMutableArray alloc] init];
        self.isRefresh = NO;
        [self.tableView setContentOffset:CGPointZero];
    } else {
        postList = self.postList;
    }
    
    NSInteger index = postList.count;
    
    for (BUCPost *post in list) {
        if ([self isLoadedBefore:post against:postList]) {
            continue;
        }
        
        post.index = index;
        [self calculateFrameOfPost:post];
        [postList addObject:post];
        index = index + 1;
    }
    
    self.postList = postList;
    [self.tableView reloadData];
}


- (void)calculateFrameOfPost:(BUCPost *)post {
    static NSTextStorage *textStorage;
    static BUCTextContainer *textContainer;
    static BUCLayoutManager *layoutManager;;
    static CGPoint contentOrigin;
    static CGFloat contentWidth;
    static dispatch_once_t onceSecurePredicate;
    
    BUCPostDetailController * __weak weakSelf = self;
    dispatch_once(&onceSecurePredicate, ^{
        contentWidth = CGRectGetWidth(weakSelf.tableView.frame) - 2 * BUCDefaultMargin;
        textStorage = [[NSTextStorage alloc] init];
        layoutManager = [[BUCLayoutManager alloc] init];
        [textStorage addLayoutManager:layoutManager];
        textContainer = [[BUCTextContainer alloc] initWithSize:CGSizeMake(contentWidth, FLT_MAX)];
        textContainer.lineFragmentPadding = 0;
        [layoutManager addTextContainer:textContainer];
        contentOrigin = CGPointMake(BUCDefaultMargin, 45.0f + BUCDefaultMargin);
    });

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
    UIImage *defaultAvatar = self.defaultAvatar;
    // avatar
    if (post.avatar) {
        [[BUCDataManager sharedInstance] getImageFromUrl:post.avatar size:cell.avatar.frame.size onSuccess:^(UIImage *image) {
            if (image) {
                cell.avatar.image = image;
            } else {
                cell.avatar.image = defaultAvatar;
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
    cell.index.text = [NSString stringWithFormat:@"%ld楼", (long)(post.index + 1)];
    
    // dateline
    cell.dateline.text = post.dateline;
    
    // content
    UITextView *textView;
    if (cell.content) {
        textView = cell.content;
        for (UIImageView *imageView in textView.subviews) {
            if ([imageView isKindOfClass:[UIImageView class]]) {
                [imageView removeFromSuperview];
            }
        }
        
        [textView.textStorage setAttributedString:post.content];

        [self layoutImagesForTextView:textView];
        textView.frame = post.textFrame;
    } else {
        textView = [self textViewWithRichText:post.content frame:post.textFrame];
        [cell.contentView addSubview:textView];
        cell.content = textView;
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
    
    [self layoutImagesForTextView:textView];
    
    return textView;
}


- (void)layoutImagesForTextView:(UITextView *)textView {
    NSArray *attachmentList = [textView.textStorage attribute:BUCAttachmentListAttributeName atIndex:0 effectiveRange:NULL];
    if (attachmentList) {
        CGSize size = CGSizeMake(CGRectGetWidth(textView.frame), BUCImageThumbnailHeight);
        for (BUCImageAttachment *attachment in attachmentList) {
            CGRect frame = [textView.layoutManager boundingRectForGlyphRange:NSMakeRange(attachment.glyphIndex, 1) inTextContainer:textView.textContainer];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
            imageView.contentMode = UIViewContentModeCenter;
            imageView.backgroundColor = [UIColor whiteColor];
            [textView addSubview:imageView];
            
            if (attachment.gif) {
                imageView.image = attachment.gif;
            } else {
                [[BUCDataManager sharedInstance] getImageFromUrl:attachment.url size:size onSuccess:^(UIImage *image) {
                    imageView.image = image;
                }];
            }
        }
    }
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



















