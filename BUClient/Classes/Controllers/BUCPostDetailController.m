#import "BUCPostDetailController.h"
#import "BUCDataManager.h"
#import "BUCModels.h"
#import "BUCImageController.h"
#import "BUCTextStack.h"
#import "BUCTextView.h"


@interface BUCPostDetailController () <UIScrollViewDelegate>


@property (nonatomic) NSMutableArray *postList;

@property (nonatomic) NSString *from;
@property (nonatomic) NSString *to;

@property (nonatomic) UIImage *defaultAvatar;

@property (weak, nonatomic) UIView *listWrapper;

@property (nonatomic) NSDictionary *metaAttribute;

@end


@implementation BUCPostDetailController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    self.defaultAvatar = [UIImage imageNamed:@"etc/avatar.png"];
    
    self.metaAttribute = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]};
    
    self.from = @"0";
    self.to = @"20";
    
    self.postList = [[NSMutableArray alloc] init];
    
    [self refresh:nil];
}


- (void)imageTapHandler:(BUCImageAttachment *)attachment {
    BUCImageController *imageController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BUCImageController"];
    imageController.url = attachment.url;
    [self presentViewController:imageController animated:YES completion:nil];
}


- (IBAction)refresh:(id)sender {
    [self displayLoading];
    [self loadList];
}


#pragma mark - private methods
- (void)loadList {
    BUCPostDetailController * __weak weakSelf = self;
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
    
    [dataManager
     getPost:self.post.pid
     
     from:self.from
     
     to:self.to
     
     onSuccess:^(NSArray *list) {
         [weakSelf buildList:list];
         [weakSelf hideLoading];
     }
     
     onError:^(NSError *error) {
         [weakSelf hideLoading];
         [weakSelf alertMessage:error.localizedDescription];
     }];
}


- (void)buildList:(NSArray *)list {
    UIScrollView *context = (UIScrollView *)self.view;
    
    UIView *wrapper;
    CGFloat layoutPointX = BUCDefaultPadding;
    CGFloat layoutPointY;
    if (self.postList.count == 0) {
        wrapper = [[UIView alloc] init];
        wrapper.backgroundColor = [UIColor whiteColor];
        self.listWrapper = wrapper;
        layoutPointY = BUCDefaultPadding;
    } else {
        wrapper = self.listWrapper;
        layoutPointY = CGRectGetHeight(wrapper.frame) + BUCDefaultMargin + BUCDefaultPadding;
    }
    
    CGFloat wrapperWidth = CGRectGetWidth(context.frame);
    CGFloat contentWidth = wrapperWidth - 2 * BUCDefaultPadding;
    
    CGFloat avatarWidth = 40.0f;
    CGFloat avatarHeight = 40.0f;
    
    NSInteger index = self.postList.count;
    
//    BUCPostDetailController * __weak weakSelf = self;
    
    for (BUCPost *post in list) {
        CGFloat savedLayoutPointY = layoutPointY;
        
        // avatar
        UIImageView *avatar = [[UIImageView alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, avatarWidth, avatarHeight)];
        avatar.contentMode = UIViewContentModeScaleAspectFit;
        avatar.image = self.defaultAvatar;
        avatar.tag = index;
        if (post.avatar) {
            [[BUCDataManager sharedInstance] getImageFromUrl:post.avatar onSuccess:^(UIImage *image) {
                avatar.image = image;
            }];
        }
        [wrapper addSubview:avatar];
        layoutPointX = layoutPointX + avatarWidth + BUCDefaultMargin;
        
        // username
        UIButton *poster = [self buttonWithRichText:post.user location:CGPointMake(layoutPointX, layoutPointY)];
        poster.tag = index;
        [wrapper addSubview:poster];
        
        if ([post.user isEqualToAttributedString:self.post.user]) {
            UILabel *op = [self opLabelAtLocation:CGPointMake(layoutPointX + CGRectGetWidth(poster.frame) + BUCDefaultMargin, layoutPointY)];
            [wrapper addSubview:op];
        }
        
        layoutPointY = layoutPointY + CGRectGetHeight(poster.frame) + BUCDefaultMargin;
        
        // post index
        UILabel *postIndex = [[UILabel alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, 0, 0)];
        postIndex.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu楼", (unsigned long)(index + 1)] attributes:self.metaAttribute];
        index = index + 1;
        [postIndex sizeToFit];
        [wrapper addSubview:postIndex];
        
        // dateline
        UILabel *dateline = [[UILabel alloc] initWithFrame:CGRectMake(layoutPointX + CGRectGetWidth(postIndex.frame) + BUCDefaultMargin, layoutPointY, 0, 0)];
        dateline.attributedText = post.dateline;
        [dateline sizeToFit];
        [wrapper addSubview:dateline];
        
        layoutPointX = BUCDefaultPadding;
        layoutPointY = savedLayoutPointY + avatarHeight + BUCDefaultMargin;
        
        // post body
        if (post.content) {
//            BUCTextView *textBlock = [[BUCTextView alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 0) richText:post.content];
//            [textBlock sizeToFit];
//            textBlock.linkTapHandler = ^(BUCLinkAttribute *linkAttribute) {
//                [weakSelf handleLinkTap];
//            };
//            
//            textBlock.imageTapHandler = ^(BUCImageAttachment *attachment) {
//                [weakSelf handleImageTap];
//            };

            UITextView *textBlock = [self shit:post.content frame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 0)];
            [wrapper addSubview:textBlock];
            layoutPointY = layoutPointY + CGRectGetHeight(textBlock.frame) + BUCDefaultPadding;
        }
        
        UIView *border = [[UIView alloc] initWithFrame:CGRectMake(0, layoutPointY, wrapperWidth, BUCBorderWidth)];
        border.backgroundColor = [UIColor lightGrayColor];
        [wrapper addSubview:border];
        
        layoutPointY = layoutPointY + BUCDefaultMargin;
    }
    
    layoutPointY = layoutPointY - BUCDefaultMargin;
    wrapper.frame = CGRectMake(0, 0, CGRectGetWidth(context.frame), layoutPointY);
    [context addSubview:wrapper];

    if (layoutPointY <= CGRectGetHeight(context.frame)) {
        layoutPointY = CGRectGetHeight(context.frame) + 1.0f;
    }

    context.contentSize = CGSizeMake(CGRectGetWidth(context.frame), layoutPointY);
}

- (void)handleLinkTap {
    NSLog(@"link tapped");
}


- (void)handleImageTap {
    NSLog(@"image tapped");
}


- (UILabel *)opLabelAtLocation:(CGPoint)location {
    UILabel *op = [[UILabel alloc] init];
    op.attributedText = [[NSAttributedString alloc] initWithString:@"OP" attributes:self.metaAttribute];
    op.textAlignment = NSTextAlignmentCenter;
    [op sizeToFit];
    op.frame = CGRectOffset(op.frame, location.x, location.y);
    op.frame = CGRectInset(op.frame, -2.0f, -2.0f);
    op.backgroundColor = op.tintColor;
    op.textColor = [UIColor whiteColor];
    
    return op;
}


- (UITextView *)shit:(NSAttributedString *)richText frame:(CGRect)frame {
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:richText];
    BUCLayoutManager *layoutManager = [[BUCLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    BUCTextContainer *textContainer = [[BUCTextContainer alloc] initWithSize:CGSizeMake(CGRectGetWidth(frame), FLT_MAX)];
    textContainer.lineFragmentPadding = 0;
    
    [layoutManager addTextContainer:textContainer];

    [layoutManager ensureLayoutForTextContainer:textContainer];
    CGRect textFrame = [layoutManager usedRectForTextContainer:textContainer];
    textFrame.origin = frame.origin;
    textFrame.size.width = CGRectGetWidth(frame);
    textFrame.size.height = ceilf(textFrame.size.height) + BUCDefaultPadding + BUCDefaultMargin;

    UITextView *textView = [[UITextView alloc] initWithFrame:textFrame textContainer:textContainer];
    textView.textContainerInset = UIEdgeInsetsZero;
    textView.editable = NO;
    textView.scrollEnabled = NO;
    
    NSArray *attachmentList = [textStorage attribute:BUCAttachmentListAttributeName atIndex:0 effectiveRange:NULL];
    if (attachmentList) {
        for (BUCImageAttachment *attachment in attachmentList) {
            CGRect frame = [layoutManager boundingRectForGlyphRange:NSMakeRange(attachment.glyphIndex, 1) inTextContainer:textContainer];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            if (attachment.gif) {
                imageView.image = attachment.gif;
            } else {
                [[BUCDataManager sharedInstance] getImageFromUrl:attachment.url onSuccess:^(UIImage *image) {
                    imageView.image = image;
                }];
            }
            
            [textView addSubview:imageView];
        }
    }
    
    return textView;
}


- (UIButton *)buttonWithRichText:(NSAttributedString *)richText location:(CGPoint)location {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setAttributedTitle:richText forState:UIControlStateNormal];
    [button sizeToFit];
    CGRect frame = button.frame;
    frame.size = button.titleLabel.frame.size;
    frame.origin = location;
    button.frame = frame;
    
    return button;
}


@end



















