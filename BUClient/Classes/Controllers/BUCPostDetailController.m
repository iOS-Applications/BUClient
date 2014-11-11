#import "BUCPostDetailController.h"
#import "BUCDataManager.h"
#import "BUCPost.h"
#import "BUCPostFragment.h"
#import "BUCTextButton.h"


@interface BUCPostDetailController () <UIScrollViewDelegate>


@property (nonatomic) NSArray *postList;

@property (nonatomic) NSString *from;
@property (nonatomic) NSString *to;

@property (nonatomic) UIImage *defaultAvatar;

@property (weak, nonatomic) UIView *listWrapper;


@end


@implementation BUCPostDetailController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.defaultAvatar = [UIImage imageNamed:@"etc/avatar.gif"];
    
    self.from = @"0";
    self.to = @"20";
//    self.postID = @"10581969";
//    self.postID = @"10581716";
    [self refresh:nil];
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
         weakSelf.postList = list;
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
    
    UIView *wrapper = [[UIView alloc] init];
    wrapper.backgroundColor = [UIColor whiteColor];
    
    // set up basic geometry
    CGFloat leftPadding = 5.0f;
    CGFloat topPadding = 10.0f;
    CGFloat rightPadding = 5.0f;
    
//    CGFloat postMetaRowGap = 2.0f;
    CGFloat metaBottomMargin = 5.0f;
    
    CGFloat wrapperWidth = CGRectGetWidth(context.frame);
    CGFloat contentWidth = wrapperWidth - leftPadding - rightPadding;
    
    CGFloat separatorHeight = 0.6f;
    
    CGFloat avatarWidth = 40.0f;
    CGFloat avatarHeight = 40.0f;
    CGFloat avatarMarginRight = 5.0f;
    
    CGFloat metaMarginBottom = 10.0f;
    
    CGFloat headingMarginBottom = 10.0f;
    
    CGFloat bodyBlockBottomMargin = 10.0f;
    
    CGFloat layoutPointX = leftPadding;
    CGFloat layoutPointY = topPadding;
    
    for (BUCPost *post in list) {
        if (layoutPointY > topPadding) {
            // separator
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, contentWidth, separatorHeight)];
            separator.backgroundColor = [UIColor lightGrayColor];
            [wrapper addSubview:separator];
            layoutPointY = layoutPointY + separatorHeight + topPadding;
        }
        
        CGFloat newLayoutPointY = layoutPointY;
        // avatar
        UIImageView *avatar = [[UIImageView alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, avatarWidth, avatarHeight)];
        avatar.contentMode = UIViewContentModeScaleAspectFit;
        avatar.image = self.defaultAvatar;
        if (post.avatar.length) {
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
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 0.0f)];
            title.numberOfLines = 0;
            title.lineBreakMode = NSLineBreakByCharWrapping;
            title.attributedText = post.title;
            [title sizeToFit];
            [wrapper addSubview:title];
            layoutPointY = layoutPointY + CGRectGetHeight(title.frame) + headingMarginBottom;
        }
        
        // post body
        for (BUCPostFragment *fragment in post.fragments) {
            if (fragment.isRichText) {
                UITextView *textBlock = [[UITextView alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 0)];
                textBlock.backgroundColor = [UIColor clearColor];
                textBlock.textContainer.lineFragmentPadding = 0;
                textBlock.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
                textBlock.editable = NO;
                textBlock.scrollEnabled = NO;
                textBlock.attributedText = fragment.richText;
                [textBlock sizeToFit];
                [wrapper addSubview:textBlock];
                layoutPointY = layoutPointY + CGRectGetHeight(textBlock.frame) + bodyBlockBottomMargin;
            } else if (fragment.isBlock) {
                UIView *block = [self blockWithFragment:fragment frame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 0)];
                [wrapper addSubview:block];
                layoutPointY = layoutPointY + CGRectGetHeight(block.frame) + bodyBlockBottomMargin;
            }
        }
    }
    
    
    wrapper.frame = CGRectMake(0, 0, CGRectGetWidth(context.frame), layoutPointY);
    [context addSubview:wrapper];
    self.listWrapper = wrapper;

    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, layoutPointY, CGRectGetWidth(context.frame), separatorHeight)];
    separator.backgroundColor = [UIColor lightGrayColor];
    [context addSubview:separator];
    layoutPointY = layoutPointY + separatorHeight;

    if (layoutPointY <= CGRectGetHeight(context.frame)) {
        layoutPointY = CGRectGetHeight(context.frame) + 1.0f;
    }

    context.contentSize = (CGSize){CGRectGetWidth(context.frame), layoutPointY};
    [context setNeedsLayout];
}


- (UIView *)blockWithFragment:(BUCPostFragment *)block frame:(CGRect)arect {
    CGFloat leftPadding = 10.0f;
    CGFloat topPadding = 5.0f;
    CGFloat rightPadding = 10.0f;
    
    CGFloat x = CGRectGetMinX(arect);
    CGFloat y = CGRectGetMinY(arect);
    CGFloat contextWidth = CGRectGetWidth(arect);
    
    CGFloat contentWidth = contextWidth - leftPadding - rightPadding;
    
    if (contextWidth <= 0) {
        return nil;
    }
    
    CGFloat fragmentBottomMargin = 10.0f;
    
    UIView *context = [[UIView alloc] init];
    context.backgroundColor = [UIColor groupTableViewBackgroundColor];
    context.layer.borderColor = [UIColor lightGrayColor].CGColor;
    context.layer.borderWidth = 1.0f;
    
    CGFloat layoutPointX = leftPadding;
    CGFloat layoutPointY = topPadding;
    
    for (BUCPostFragment *fragment in block.children) {
        if (fragment.isRichText) {
            UITextView *textBlock = [[UITextView alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 0)];
            textBlock.textContainer.lineFragmentPadding = 0;
            textBlock.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
            textBlock.editable = NO;
            textBlock.scrollEnabled = NO;
            textBlock.backgroundColor = [UIColor clearColor];
            textBlock.attributedText = fragment.richText;
            [textBlock sizeToFit];
            textBlock.contentSize = CGSizeMake(600.0f, CGRectGetHeight(textBlock.frame));
            [context addSubview:textBlock];
            layoutPointY = layoutPointY + CGRectGetHeight(textBlock.frame) + fragmentBottomMargin;
        } else if (fragment.isBlock) {
            UIView *block = [self blockWithFragment:fragment frame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 0)];
            [context addSubview:block];
            layoutPointY = layoutPointY + CGRectGetHeight(block.frame) + fragmentBottomMargin;
        }
    }
    
    context.frame = CGRectMake(x, y, contextWidth, layoutPointY);
    
    return context;
}


- (BUCTextButton *)buttonFromTitle:(NSAttributedString *)title origin:(CGPoint)origin {
    BUCTextButton *button = [[BUCTextButton alloc] init];
    [button setTitle:title];
    [button sizeToFit];
    button.frame = CGRectOffset(button.frame, origin.x, origin.y);
    
    return button;
}


- (UILabel *)labelFromText:(NSAttributedString *)text origin:(CGPoint)origin {
    UILabel *label = [[UILabel alloc] init];
    label.attributedText = text;
    [label sizeToFit];
    label.frame = CGRectOffset(label.frame, origin.x, origin.y);
    
    return label;
}


@end



















