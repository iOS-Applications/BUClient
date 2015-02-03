#import "BUCNewPostController.h"
#import "BUCForumListController.h"
#import "BUCEditorController.h"
#import "BUCConstants.h"
#import "BUCDataManager.h"
#import "BUCAppDelegate.h"

@interface BUCNewPostController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *forum;
@property (weak, nonatomic) IBOutlet UILabel *thread;

@property (weak, nonatomic) IBOutlet UITextField *subject;
@property (weak, nonatomic) IBOutlet UILabel *attachment;
@property (weak, nonatomic) IBOutlet UITextView *content;
@property (weak, nonatomic) IBOutlet UIButton *addForum;
@property (nonatomic) UIImage *imageAttachment;

@property (nonatomic) BUCAppDelegate *appDelegate;

@property (nonatomic) CGFloat screenWidth;
@property (nonatomic) CGFloat nativeWidth;
@property (nonatomic) CGFloat nativeHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *threadWidth;

@end

@implementation BUCNewPostController
#pragma mark - set up
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.appDelegate = (BUCAppDelegate *)[UIApplication sharedApplication].delegate;
    
    [self setupLayout];
    
    self.thread.text = self.parentTitle;
    self.forum.text = self.forumName;
    NSString *signature = [[NSUserDefaults standardUserDefaults] stringForKey:@"signature"];
    if (signature) {
        self.content.text = [NSString stringWithFormat:@"%@", signature];
    }
    
    if (self.fid) {
        self.addForum.hidden = YES;
    }
    
    self.content.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.content.layer.borderWidth = BUCBorderWidth;
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

    self.threadWidth.constant = self.screenWidth - 70.0f;
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
        self.threadWidth.constant = self.screenWidth - 70.0f;
    }
}


#pragma mark - text view delegate
- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.content.scrollEnabled = YES;
}


- (void)textViewDidEndEditing:(UITextView *)textView {
    self.content.scrollEnabled = NO;
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    BUCForumListController *forumList = (BUCForumListController *)(((UINavigationController *)segue.destinationViewController).topViewController);
    forumList.unwindIdentifier = @"forumListToNewPost";
}


- (IBAction)unwindToNewPost:(UIStoryboardSegue *)segue {
    BUCForumListController *forumList = (BUCForumListController *)segue.sourceViewController;
    NSDictionary *forum = forumList.selected;
    self.fid = [forum objectForKey:@"fid"];
    self.forumName = [forum objectForKey:@"name"];
    self.forum.text = self.forumName;
}


- (IBAction)cancel {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)send {
    BOOL invalid = NO;
    if (self.fid) {
        if (self.subject.text.length == 0) {
            [self.appDelegate alertWithMessage:@"请输入标题"];
            invalid = YES;
        } else if (self.content.text.length == 0) {
            [self.appDelegate alertWithMessage:@"请输入内容"];
            invalid = YES;
        }
    } else if (self.tid) {
        if (self.content.text.length == 0) {
            [self.appDelegate alertWithMessage:@"请输入内容"];
            invalid = YES;
        }
    } else {
        [self.appDelegate alertWithMessage:@"请选择版块"];
        invalid = YES;
    }
    if (invalid) {
        return;
    }

    [[BUCDataManager sharedInstance] newPostToForum:self.fid
                                             thread:self.tid
                                            subject:self.subject.text
                                            content:self.content.text
                                         attachment:self.imageAttachment
                                          onSuccess:^(NSString *tid) {
                                              self.tid = tid;
                                              [self performSegueWithIdentifier:self.unwindIdentifier sender:nil];
                                          }
                                            onError:^(NSString *errorMsg) {
                                                [self.appDelegate alertWithMessage:errorMsg];
                                            }];
}

@end
