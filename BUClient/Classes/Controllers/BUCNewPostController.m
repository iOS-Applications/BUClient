#import "BUCNewPostController.h"
#import "BUCForumListController.h"
#import "BUCEditorController.h"
#import "BUCConstants.h"
#import "BUCDataManager.h"
#import "BUCAppDelegate.h"

@interface BUCNewPostController ()

@property (weak, nonatomic) IBOutlet UILabel *forum;
@property (weak, nonatomic) IBOutlet UILabel *thread;
@property (weak, nonatomic) IBOutlet UILabel *subject;
@property (weak, nonatomic) IBOutlet UILabel *attachment;
@property (weak, nonatomic) IBOutlet UITextView *content;
@property (weak, nonatomic) IBOutlet UIButton *addForum;
@property (nonatomic) UIImage *imageAttachment;

@property (nonatomic) BUCAppDelegate *appDelegate;

@end

@implementation BUCNewPostController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.appDelegate = (BUCAppDelegate *)[UIApplication sharedApplication].delegate;
    
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


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 4) {
        CGSize size = self.content.intrinsicContentSize;
        return size.height + 38.0f;
    }
    
    return 44.f;
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"newPostToForumList"]) {
        BUCForumListController *forumList = (BUCForumListController *)(((UINavigationController *)segue.destinationViewController).topViewController);
        forumList.unwindIdentifier = @"forumListToNewPost";
    } else if ([segue.identifier isEqualToString:@"newPostSubjectToEditor"]) {
        BUCEditorController *editor = (BUCEditorController *)segue.destinationViewController;
        editor.content = self.subject.text;
        editor.unwindIdentifier = @"editorSubjectToNewPost";
        editor.lengthLimit = 100;
        editor.navigationItem.title = @"Subject";
    } else if ([segue.identifier isEqualToString:@"newPostContentToEditor"]) {
        BUCEditorController *editor = (BUCEditorController *)segue.destinationViewController;
        editor.content = self.content.text;
        editor.unwindIdentifier = @"editorContentToNewPost";
        editor.lengthLimit = 10000;
        editor.navigationItem.title = @"Content";
    }
}


- (IBAction)unwindToNewPost:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"forumListToNewPost"]) {
        BUCForumListController *forumList = (BUCForumListController *)segue.sourceViewController;
        NSDictionary *forum = forumList.selected;
        self.fid = [forum objectForKey:@"fid"];
        self.forumName = [forum objectForKey:@"name"];
        self.forum.text = self.forumName;
    } else if ([segue.identifier isEqualToString:@"editorSubjectToNewPost"]) {
        BUCEditorController *editor = (BUCEditorController *)segue.sourceViewController;
        self.subject.text = editor.content;
        self.postTitle = editor.content;
    } else if ([segue.identifier isEqualToString:@"editorContentToNewPost"]) {
        BUCEditorController *editor = (BUCEditorController *)segue.sourceViewController;
        self.content.text = editor.content;
    }
}

- (IBAction)openEditor {
    [self performSegueWithIdentifier:@"newPostContentToEditor" sender:nil];
}

- (IBAction)cancel {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)send {
    BUCNewPostController * __weak weakSelf = self;
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
        [self.appDelegate alertWithMessage:@"请选择论坛"];
        invalid = YES;
    }
    if (invalid) {
        return;
    }

    [self.appDelegate displayLoading];
    [[BUCDataManager sharedInstance] newPostToForum:self.fid thread:self.tid subject:self.subject.text content:self.content.text attachment:self.imageAttachment onSuccess:^(NSString *tid) {
        weakSelf.tid = tid;
        [weakSelf.appDelegate hideLoading];
        [weakSelf performSegueWithIdentifier:weakSelf.unwindIdentifier sender:nil];
    } onError:^(NSError *error) {
        [weakSelf.appDelegate hideLoading];
        [weakSelf.appDelegate alertWithMessage:error.localizedDescription];
    }];
}

@end
