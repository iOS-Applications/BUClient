#import "BUCEditorController.h"
#import "BUCAppDelegate.h"

@interface BUCEditorController () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic) BOOL textChanged;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewBottomSpace;
@property (nonatomic) BUCAppDelegate *appDelegate;
@end

@implementation BUCEditorController
#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = self.title;
    self.appDelegate = (BUCAppDelegate *)[UIApplication sharedApplication].delegate;
    self.textChanged = NO;
    
    self.textView.text = self.content;
    self.textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.textView.layer.borderWidth = 0.5f;
    [self.textView becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - managing the keyboard
- (void)keyboardWasShown:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.textViewBottomSpace.constant = kbSize.height;
}

- (void)keyboardWillBeHidden:(NSNotification*)notification {
    self.textViewBottomSpace.constant = 8.0f;
}


#pragma mark - text view delegate
- (void)textViewDidChange:(UITextView *)textView {
    self.textChanged = YES;
}


#pragma mark - Navigation
/*
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.content = self.textView.text;
}
 */

- (IBAction)doneEditing:(id)sender {
    if (self.textView.text && self.textChanged) {
        self.content = self.textView.text;
        if ([self.title isEqualToString:@"Signature"]) {
            [self performSegueWithIdentifier:@"newSignature" sender:nil];
        } else if ([self.title isEqualToString:@"Reply"]) {
            [self performSegueWithIdentifier:@"newReply" sender:nil];
        } else {
            [self performSegueWithIdentifier:@"newPost" sender:nil];
        }
    } else {
        [self.appDelegate alertWithMessage:@"请编辑文本"];
    }
}


@end
