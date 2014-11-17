#import "BUCPostDetailController.h"
#import "BUCDataManager.h"
#import "BUCTextButton.h"
#import "BUCImageController.h"
#import "BUCModels.h"
#import "BUCTextStack.h"
#import "BUCTextView.h"


@interface BUCPostDetailController () <UIScrollViewDelegate, UITextViewDelegate>


@property (nonatomic) NSArray *postList;

@property (nonatomic) NSString *from;
@property (nonatomic) NSString *to;

@property (nonatomic) UIImage *defaultAvatar;

@property (weak, nonatomic) UIView *listWrapper;


@end


@implementation BUCPostDetailController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    self.defaultAvatar = [UIImage imageNamed:@"etc/avatar.gif"];
    
    self.from = @"0";
    self.to = @"20";
//    self.postID = @"10578633";
    
    [self refresh:nil];
}


- (void)didReceiveMemoryWarning {
    NSLog(@"memory waring!");
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
     getPost:self.postID
     
     from:self.from
     
     to:self.to
     
     onSuccess:^(NSArray *list) {
//         weakSelf.postList = list;
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
    
    UIView *wrapper = [[UIView alloc] initWithFrame:CGRectZero];
    wrapper.backgroundColor = [UIColor whiteColor];
    
    // set up basic geometry
    CGFloat leftPadding = 5.0f;
    CGFloat topPadding = 10.0f;
    CGFloat rightPadding = 5.0f;
    
//    CGFloat postMetaRowGap = 2.0f;
    CGFloat metaBottomMargin = 5.0f;
    
    CGFloat wrapperWidth = CGRectGetWidth(context.frame);
    CGFloat contentWidth = wrapperWidth - leftPadding - rightPadding;
    
    CGFloat avatarWidth = 40.0f;
    CGFloat avatarHeight = 40.0f;
    CGFloat avatarMarginRight = 5.0f;
    
    CGFloat metaMarginBottom = 10.0f;
    
    CGFloat headingMarginBottom = 10.0f;
    
    CGFloat postBottomMargin = 5.0f;
    
    CGFloat layoutPointX = leftPadding;
    CGFloat layoutPointY = topPadding;
    
    for (BUCPost *post in list) {
        CGFloat newLayoutPointY = layoutPointY;
        // avatar
        UIImageView *avatar = [[UIImageView alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, avatarWidth, avatarHeight)];
        avatar.contentMode = UIViewContentModeScaleAspectFit;
        avatar.image = self.defaultAvatar;
        if (post.avatar) {
            [[BUCDataManager sharedInstance] getImageFromUrl:post.avatar onSuccess:^(UIImage *image) {
                avatar.image = image;
            }];
        }
        [wrapper addSubview:avatar];
        layoutPointX = layoutPointX + avatarWidth + avatarMarginRight;
        
        // username
        BUCTextButton *poster = [self buttonFromTitle:post.user origin:(CGPoint){layoutPointX, layoutPointY}];
        [wrapper addSubview:poster];
        layoutPointY = layoutPointY + CGRectGetHeight(poster.frame) + metaBottomMargin;
        
        // dateline
        UILabel *dateline = [[UILabel alloc] init];
        dateline.text = post.dateline;
        [dateline sizeToFit];
        dateline.frame = CGRectOffset(dateline.frame, layoutPointX, layoutPointY);
        [wrapper addSubview:dateline];
        
        layoutPointX = leftPadding;
        layoutPointY = newLayoutPointY + avatarHeight + metaMarginBottom;
        
        // post title
        if (post.title.length) {
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 0)];
            title.numberOfLines = 0;
            title.attributedText = post.title;
            [title sizeToFit];
            [wrapper addSubview:title];
            layoutPointY = layoutPointY + CGRectGetHeight(title.frame) + headingMarginBottom;
        }
        
        // post body
        if (post.content) {
            UITextView *textBlock = [self textStackWithRichText:post.content frame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 1.0f)];
            [wrapper addSubview:textBlock];
            
            layoutPointY = layoutPointY + CGRectGetHeight(textBlock.frame) + postBottomMargin;
        }
    }
    
    wrapper.frame = CGRectMake(0, 0, CGRectGetWidth(context.frame), layoutPointY);
    [context addSubview:wrapper];
    self.listWrapper = wrapper;

    if (layoutPointY <= CGRectGetHeight(context.frame)) {
        layoutPointY = CGRectGetHeight(context.frame) + 1.0f;
    }

    context.contentSize = CGSizeMake(CGRectGetWidth(context.frame), layoutPointY);
}


- (BUCTextButton *)buttonFromTitle:(NSAttributedString *)title origin:(CGPoint)origin {
    BUCTextButton *button = [[BUCTextButton alloc] init];
    [button setTitle:title];
    [button sizeToFit];
    button.frame = CGRectOffset(button.frame, origin.x, origin.y);
    
    return button;
}


- (BUCTextView *)textStackWithRichText:(NSAttributedString *)richText frame:(CGRect)frame {
    NSTextStorage* textStorage = [[NSTextStorage alloc] initWithAttributedString:richText];
    BUCLayoutManager *layoutManager = [[BUCLayoutManager alloc] init];
    BUCTextContainer *textContainer = [[BUCTextContainer alloc] initWithSize:CGSizeMake(CGRectGetWidth(frame), FLT_MAX)];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    
    [layoutManager ensureLayoutForTextContainer:textContainer];
    CGRect shit = [layoutManager usedRectForTextContainer:textContainer];
    BUCTextView *textView = [[BUCTextView alloc] initWithFrame:shit textContainer:textContainer];
    textView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, shit.size.height);
    textView.contentSize = CGSizeMake(frame.size.width, shit.size.height);
    textView.delegate = self;
    
    NSArray *attachmentList = [richText attribute:BUCAttachmentListAttributeName atIndex:0 effectiveRange:NULL];
    if (attachmentList) {
        [layoutManager ensureLayoutForTextContainer:textContainer];
        for (BUCImageAttachment *attachment in attachmentList) {
            CGRect frame = [layoutManager boundingRectForGlyphRange:NSMakeRange(attachment.glyphIndex, 1) inTextContainer:textContainer];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
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


@end



















