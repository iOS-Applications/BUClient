#import "BUCPostDetailController.h"
#import "BUCDataManager.h"
#import "BUCModels.h"
#import "BUCImageController.h"
#import "BUCTextStack.h"
#import "BUCAppDelegate.h"
#import "BUCNewPostController.h"
#import "BUCPostListCell.h"

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
@property (nonatomic) CGRect avatarBounds;
@property (nonatomic) CGSize imageSize;

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
@property (weak, nonatomic) IBOutlet UILabel *bottomLoadingLabel;


@end

static NSUInteger const BUCAPIMaxLoadRowCount = 20;
static NSUInteger const BUCPostPageMaxRowCount = 40;

@implementation BUCPostDetailController
#pragma mark - setup
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
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        [self.appDelegate hideLoading];
        [[BUCDataManager sharedInstance] cancelAllImageTasks];
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self didRotateFromInterfaceOrientation:0];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textStyleChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShown:) name:UIKeyboardWillShowNotification object:nil];
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
    
    UIFont *metaFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.metaAttribute = @{NSFontAttributeName:metaFont};
    self.opTag = [[NSAttributedString alloc] initWithString:@" [楼主]" attributes:@{NSFontAttributeName:metaFont, NSForegroundColorAttributeName:self.view.tintColor}];
    self.metaLineHeight = ceilf(metaFont.lineHeight);
    
    self.avatarBounds = CGRectMake(BUCDefaultPadding, BUCDefaultMargin, 40.0f, 40.0f);
    self.imageSize = CGSizeMake(100.0f, 100.0f);
    self.defaultAvatar = [UIImage imageNamed:@"avatar"];
    self.defaultImage = [UIImage imageNamed:@"loading"];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textStyleChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    NSMutableArray *barButtons = [self.navigationItem.rightBarButtonItems mutableCopy];
    [barButtons addObject:self.replyButton];
    self.navigationItem.rightBarButtonItems = barButtons;
    self.topRotateArrow.transform = CGAffineTransformMakeRotation(M_PI);
    
    self.appDelegate = (BUCAppDelegate *)[UIApplication sharedApplication].delegate;
    self.postList = [[NSMutableArray alloc] init];
    self.pidSet = [[NSMutableSet alloc] init];
    self.opList = [[NSMutableArray alloc] init];
    self.opIndexSet = [[NSMutableIndexSet alloc] init];
    self.insertIndexPaths = [[NSMutableArray alloc] init];
    
    self.star.selected = [[BUCDataManager sharedInstance] lookupBookmarkOfThread:self.rootPost.tid];
    
    [self setupLayout];
    
    [self.appDelegate displayLoading];
    [[BUCDataManager sharedInstance] resumeAllImageTasks];
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


#pragma mark - list data management
- (void)buildList:(NSArray *)list count:(NSUInteger)count{
    if (!self.flush) {
        [self.insertIndexPaths removeAllObjects];
    } else {
        [self.pidSet removeAllObjects];
        [self.opList removeAllObjects];
        self.rowCount = 0;
    }
    
    NSUInteger index = self.rowCount;
    NSUInteger maxRowCount = self.postList.count;
    for (NSUInteger i = 0; i < count; i = i + 1) {
        BUCPost *post = [list objectAtIndex:i];
        if ([self.pidSet containsObject:post.pid]) {
            continue;
        }
        
        [self.pidSet addObject:post.pid];
        
        BUCPost *reusablePost;
        if (maxRowCount <= index) {
            reusablePost = [[BUCPost alloc] initWithTextStack];
            [self.postList addObject:reusablePost];
        } else {
            reusablePost = [self.postList objectAtIndex:index];
        }
        reusablePost.content = post.content;
        [reusablePost.textStorage setAttributedString:post.content.richText];
        reusablePost.user = post.user;
        reusablePost.pid = post.pid;
        reusablePost.index = index + self.from;
        reusablePost.avatar = post.avatar;
        reusablePost.date = post.date;
        [self layoutPost:reusablePost];
        
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
    NSUInteger to = from + BUCAPIMaxLoadRowCount;
    BUCPostDetailController * __weak weakSelf = self;
    [[BUCDataManager sharedInstance]
     listOfPost:self.rootPost.tid
     
     from:[NSString stringWithFormat:@"%lu", (unsigned long)from]
     
     to:[NSString stringWithFormat:@"%lu", (unsigned long)to]
     
     onSuccess:^(NSArray *list, NSUInteger count) {
         if (weakSelf) {
             if (weakSelf.flush) {
                 weakSelf.from = from;
             }
             if (from == 0) {
                 weakSelf.rootPost.uid = ((BUCPost *)[list objectAtIndex:from]).uid;
             }
             weakSelf.to = to;
             [weakSelf buildList:list count:count];
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (weakSelf.flush || weakSelf.reverse) {
                     [weakSelf.tableView setContentOffset:CGPointZero];
                     [weakSelf.tableView reloadData];
                 } else if (weakSelf.opOnly) {
                     [weakSelf.tableView reloadData];
                 } else if (weakSelf.insertIndexPaths.count > 0) {
                     [weakSelf.tableView insertRowsAtIndexPaths:weakSelf.insertIndexPaths
                                               withRowAnimation:UITableViewRowAnimationNone];
                 }
                 
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


- (void)refreshFrom:(NSInteger)from {
    self.loading = YES;
    self.flush = YES;
    
    [[BUCDataManager sharedInstance]
     childCountOfForum:nil
     thread:self.rootPost.tid
     
     onSuccess:^(NSUInteger count) {
         self.postCount = count + 1;
         self.pageCount = count / BUCPostPageMaxRowCount + 1;
         [self loadListFrom:from];
     }
     
     onError:^(NSString *errorMsg) {
         [self endLoading];
         [self.appDelegate alertWithMessage:errorMsg];
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
        [self.bottomLoadingIndicator startAnimating];
        self.bottomLoadingLabel.text = @"加载中，请等待...";
    }
    
    if (self.to > self.postCount) {
        [self loadListFrom:self.to - BUCAPIMaxLoadRowCount];
    } else {
        [self loadListFrom:self.to];
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.loading || !self.reverse) {
        return;
    }
    
    UIImageView *topArrow = self.topRotateArrow;
    if (scrollView.contentOffset.y <= -50.0f) {
        [UIView animateWithDuration:0.2 animations:^{
            topArrow.transform = CGAffineTransformIdentity;
        }];
        if (self.to >= self.postCount) {
            self.topLoadingLabel.text = @"到头了，松开后刷新";
        } else {
            self.topLoadingLabel.text = @"松开后加载更多";
        }
    } else if (scrollView.contentOffset.y < 0.0f) {
        [UIView animateWithDuration:0.2 animations:^{
            topArrow.transform = CGAffineTransformMakeRotation(M_PI);
        }];
        self.topLoadingLabel.text = @"向下拉动";
    }
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.loading || !self.reverse) {
        return;
    } else if (scrollView.contentOffset.y <= - 50.0f) {
        scrollView.bounces = NO;
        [self loadMore];
    }
}


- (void)endLoading {
    [self.appDelegate hideLoading];
    if (self.reverse) {
        self.bottomLoadingView.hidden = YES;
        self.tableView.contentInset = UIEdgeInsetsZero;
        self.topLoadingView.hidden = NO;
        self.topRotateArrow.hidden = NO;
        self.topLoadingLabel.text = @"向下拉动";
    } else {
        self.topLoadingView.hidden = YES;
        self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 50.0f, 0.0f);
        self.bottomLoadingView.hidden = NO;
        if (self.to >= self.postCount) {
            self.bottomLoadingLabel.text = @"没有更多了，点这里刷新";
        } else {
            self.bottomLoadingLabel.text = @"点这里加载更多";
        }
    }
    
    [self.topLoadingIndicator stopAnimating];
    [self.bottomLoadingIndicator stopAnimating];
    self.loading = NO;
    self.tableView.bounces = YES;
    self.currentPage = (self.to + BUCAPIMaxLoadRowCount) / BUCPostPageMaxRowCount;
    self.navigationItem.titleView = nil;
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


- (void)layoutPost:(BUCPost *)post {
    post.textContainer.size = CGSizeMake(self.contentWidth, FLT_MAX);
    [post.layoutManager ensureLayoutForTextContainer:post.textContainer];
    CGRect frame = [post.layoutManager usedRectForTextContainer:post.textContainer];
    frame.size.height = ceilf(frame.size.height);
    
    post.cellWidth = self.screenWidth;
    post.cellHeight = BUCDefaultMargin * 4.0f + frame.size.height + 40.0f;
    post.bounds = CGRectMake(0.0f, 0.0f, self.screenWidth, post.cellHeight);
}


- (void)relayoutList {
    BUCPostDetailController * __weak weakSelf = self;
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
    BUCPost *post = [self getPostWithIndexpath:indexPath];
    return post.cellHeight + 0.5f;
}


- (void)drawBlockList:(NSArray *)blockList post:(BUCPost *)post {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, BUCBorderWidth);
    [[UIColor colorWithWhite:0.98f alpha:1.0f] setFill];
    CGContextSaveGState(context);
    BUCTextContainer *textContainer = post.textContainer;
    for (BUCTextBlockAttribute *blockAttribute in [blockList reverseObjectEnumerator]) {
        if (blockAttribute.noBackground) {
            continue;
        }
        
        CGRect frame = CGRectIntegral([post.layoutManager boundingRectForGlyphRange:blockAttribute.range inTextContainer:textContainer]);
        frame.size.width = textContainer.size.width - 2 * (blockAttribute.padding - BUCDefaultMargin);
        frame.origin.x = blockAttribute.padding - BUCDefaultMargin;
        frame = CGRectInset(frame, 0, -BUCDefaultMargin);
        if (blockAttribute.backgroundColor) {
            CGContextSaveGState(context);
            [blockAttribute.backgroundColor setFill];
            CGContextFillRect(context, frame);
            CGContextRestoreGState(context);
        } else {
            CGContextFillRect(context, frame);
        }
        
        CGContextStrokeRect(context, frame);
    }
    CGContextRestoreGState(context);
}


- (UIImage *)drawBackgroundWithPost:(BUCPost *)post {
    UIImage *output;
    UIGraphicsBeginImageContextWithOptions(post.bounds.size, YES, 0.0f);
    [[UIColor whiteColor] setFill];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:post.bounds];
    [path fill];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    NSMutableAttributedString *user = [[NSMutableAttributedString alloc] initWithString:post.user attributes:self.metaAttribute];
    if ([self.opIndexSet containsIndex:post.index]) {
        [user appendAttributedString:self.opTag];
    }
    [user drawAtPoint:CGPointMake(40.0f + BUCDefaultMargin + BUCDefaultPadding, BUCDefaultMargin)];
    CGContextRestoreGState(context);
    
    NSAttributedString *index = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu楼", (unsigned long)post.index + 1] attributes:self.metaAttribute];
    [index drawAtPoint:CGPointMake(self.screenWidth - BUCDefaultMargin - ceilf([index boundingRectWithSize:CGSizeMake(FLT_MAX, FLT_MAX) options:0 context:nil].size.width), BUCDefaultMargin)];
    
    NSAttributedString *date = [[NSAttributedString alloc] initWithString:post.date attributes:self.metaAttribute];
    [date drawAtPoint:CGPointMake(40.0f + BUCDefaultPadding + BUCDefaultMargin, BUCDefaultMargin * 2.0f + self.metaLineHeight)];
    
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), BUCDefaultPadding, BUCDefaultMargin * 3.0f + 40.0f);
    [self drawBlockList:post.content.blockList post:post];
    [post.layoutManager drawGlyphsForGlyphRange:NSMakeRange(0.0f, post.textStorage.length) atPoint:CGPointZero];
    
    output = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return output;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BUCPostListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    BUCPost *post = [self getPostWithIndexpath:indexPath];
    if (!cell.imageList) {
        cell.imageList = [[NSMutableArray alloc] init];
    }
    
    if (!cell.urlMap) {
        cell.urlMap = [[NSMutableDictionary alloc] init];
    }
    
    if (post.cellHeight > 1000.0f) {
        [self.appDelegate displayLoading];
    }

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    BUCPostDetailController * __weak weakSelf = self;
    dispatch_async(queue, ^{
        UIImage *background = [weakSelf drawBackgroundWithPost:post];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.appDelegate hideLoading];
            BUCPostListCell *cell = (BUCPostListCell *)[tableView cellForRowAtIndexPath:indexPath];
            if ([[tableView visibleCells] containsObject:cell]) {
                cell.contentView.layer.contents = (id)background.CGImage;
                cell.contentView.hidden = NO;
            }
        });
    });
    
    UIImageView *avatarView = [[UIImageView alloc] initWithFrame:self.avatarBounds];
    avatarView.backgroundColor = [UIColor whiteColor];
    avatarView.contentMode = UIViewContentModeCenter;
    avatarView.image = self.defaultAvatar;
    avatarView.tag = 100;
    [cell.contentView addSubview:avatarView];
    [cell.imageList addObject:avatarView];
    
    if (post.avatar) {
        dispatch_async(queue, ^{
            [[BUCDataManager sharedInstance] getImageWithURL:post.avatar.url size:weakSelf.avatarBounds.size onSuccess:^(UIImage *image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    BUCPostListCell *cell = (BUCPostListCell *)[tableView cellForRowAtIndexPath:indexPath];
                    if ([[tableView visibleCells] containsObject:cell]) {
                        UIImageView *avatarView = (UIImageView *)[cell.contentView viewWithTag:100];
                        avatarView.image = nil;
                        avatarView.userInteractionEnabled = YES;
                        avatarView.image = image;
                        [cell.urlMap setObject:post.avatar.url forKey:@(100)];
                    }
                });
            }];
        });
    }
    
    if (post.content.emotionList) {
        dispatch_async(queue, ^{
            for (BUCImageAttachment *attachment in post.content.emotionList) {
                CGRect frame = [post.layoutManager boundingRectForGlyphRange:NSMakeRange(attachment.glyphIndex, 1) inTextContainer:post.textContainer];
                frame.origin.x = ceilf(frame.origin.x + BUCDefaultPadding);
                frame.origin.y = ceilf(frame.origin.y + BUCDefaultMargin * 3.0f + 40.0f);
                frame.size.width = ceilf(frame.size.width);
                frame.size.height = ceilf(frame.size.height);
                UIImage *image = [[BUCDataManager sharedInstance] getImageWithPath:attachment.path];
                dispatch_async(dispatch_get_main_queue(), ^{
                    BUCPostListCell *cell = (BUCPostListCell *)[tableView cellForRowAtIndexPath:indexPath];
                    if ([[tableView visibleCells] containsObject:cell]) {
                        UIImageView *gifView = [[UIImageView alloc] initWithFrame:frame];
                        gifView.backgroundColor = [UIColor clearColor];
                        gifView.contentMode = UIViewContentModeCenter;
                        gifView.image = image;
                        [cell.contentView addSubview:gifView];
                        [cell.imageList addObject:gifView];
                    }
                });
            }
        });
    }
    
    if (post.content.imageList) {
        NSInteger tag = 101;
        for (BUCImageAttachment *attachment in post.content.imageList) {
            CGRect frame = [post.layoutManager boundingRectForGlyphRange:NSMakeRange(attachment.glyphIndex, 1) inTextContainer:post.textContainer];
            frame.origin.x = ceilf((weakSelf.screenWidth - 100.0f) / 2.0f);
            frame.origin.y = ceilf((frame.size.height - 100.0f) / 2.0f + frame.origin.y + BUCDefaultMargin * 3.0f + 40.0f);
            frame.size = weakSelf.imageSize;
            attachment.tag = tag;
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
            imageView.backgroundColor = [UIColor whiteColor];
            imageView.contentMode = UIViewContentModeCenter;
            imageView.tag = tag;
            imageView.image = weakSelf.defaultImage;
            [cell.contentView addSubview:imageView];
            [cell.imageList addObject:imageView];
            [cell.urlMap setObject:attachment.url forKey:@(imageView.tag)];
            tag = tag + 1;
        }
        
        dispatch_async(queue, ^{
            for (BUCImageAttachment *attachment in post.content.imageList) {
                [[BUCDataManager sharedInstance] getImageWithURL:attachment.url size:weakSelf.imageSize onSuccess:^(UIImage *image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        BUCPostListCell *cell = (BUCPostListCell *)[tableView cellForRowAtIndexPath:indexPath];
                        if ([[tableView visibleCells] containsObject:cell]) {
                            UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:attachment.tag];
                            imageView.userInteractionEnabled = YES;
                            imageView.image = image;
                        }
                    });
                }];
            }
        });
    }
    
    if (!self.reverse && indexPath.row == self.filterRowCount - 1 && !self.loading && self.to < self.postCount) {
        [self loadMore];
    }
    
    return cell;
}


#pragma mark - actions
- (IBAction)handlerTapOnTable:(UITapGestureRecognizer *)tap {
    CGPoint location = [tap locationInView:self.bottomLoadingView];
    if ([self.bottomLoadingView pointInside:location withEvent:nil]) {
        [self loadMore];
        return;
    }
    
    location = [tap locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    if (!indexPath) {
        return;
    }
    BUCPost *post = [self getPostWithIndexpath:indexPath];
    BUCPostListCell *cell = (BUCPostListCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    UIView *contents = cell.contentView;
    location = [tap locationInView:contents];

    UIImageView *imageView = (UIImageView *)[contents hitTest:location withEvent:nil];
    if ([imageView isKindOfClass:[UIImageView class]]) {
        [self performSegueWithIdentifier:@"postDetailToImage" sender:[cell.urlMap objectForKey:@(imageView.tag)]];
        return;
    }

    NSUInteger index;
    location.x = location.x - BUCDefaultPadding;
    location.y = location.y - 3 * BUCDefaultMargin - 40.0f;
    index = [post.layoutManager glyphIndexForPoint:location inTextContainer:post.textContainer fractionOfDistanceThroughGlyph:NULL];
    BUCLinkAttribute *link = (BUCLinkAttribute *)[post.content.richText attribute:BUCLinkAttributeName atIndex:index effectiveRange:NULL];
    BUCPostDetailController *postDetail;
    if (link.linkType == BUCPostLink) {
        postDetail = (BUCPostDetailController *)[self.storyboard instantiateViewControllerWithIdentifier:@"BUCPostDetailController"];
        postDetail.rootPost = [[BUCPost alloc] init];
        postDetail.rootPost.tid = link.linkValue;
        [self.navigationController pushViewController:postDetail animated:YES];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link.linkValue]];
    }
}

- (IBAction)toggleMenu {
    if (self.loading) {
        return;
    }
    [self dismissPageSelection];
    [self.view layoutIfNeeded];
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
        [self.view layoutIfNeeded];
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
    self.star.selected = !self.star.selected;
    if (self.star.selected) {
        [[BUCDataManager sharedInstance] bookmarkThread:self.rootPost.tid title:self.rootPost.title];
    } else {
        [[BUCDataManager sharedInstance] removeBookmarkOfThread:self.rootPost.tid];
    }
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
    if (self.reverse) {
        self.tableView.contentInset = UIEdgeInsetsZero;
    } else {
        self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 50.0f, 0.0f);
    }
    
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
    } else if ([segue.identifier isEqualToString:@"postDetailToImage"]) {
        BUCImageController *image = (BUCImageController *)segue.destinationViewController;
        image.url = (NSURL *)sender;
    }
}


@end



















