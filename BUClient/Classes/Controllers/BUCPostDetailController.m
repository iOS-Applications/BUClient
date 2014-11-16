#import "BUCPostDetailController.h"
#import "BUCDataManager.h"
#import "BUCTextButton.h"
#import "BUCImageController.h"
#import "BUCModels.h"
#import "BUCTextView.h"


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
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    self.defaultAvatar = [UIImage imageNamed:@"etc/avatar.gif"];
    
    self.from = @"0";
    self.to = @"20";
//    self.postID = @"10581932";
    self.postID = @"10582028";
    
    
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
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 0.0f)];
            title.numberOfLines = 0;
            title.attributedText = post.title;
            [title sizeToFit];
            [wrapper addSubview:title];
            layoutPointY = layoutPointY + CGRectGetHeight(title.frame) + headingMarginBottom;
        }
        
        // post body
        BUCTextView *textBlock = [[BUCTextView alloc] initWithFrame:CGRectMake(layoutPointX, layoutPointY, contentWidth, 0)];
        // set event handlers here...
        textBlock.richText = post.content;
        [textBlock sizeToFit];
        [wrapper addSubview:textBlock];
        layoutPointY = layoutPointY + CGRectGetHeight(textBlock.frame);
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


@end



















