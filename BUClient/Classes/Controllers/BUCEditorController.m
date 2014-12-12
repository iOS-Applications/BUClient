#import "BUCEditorController.h"
#import "BUCAppDelegate.h"

@interface BUCEditorController () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic) BOOL textChanged;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewBottomSpace;
@end

@implementation BUCEditorController
#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textChanged = NO;
    
    self.textView.text = self.content;
    self.textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.textView.layer.borderWidth = 0.5f;
    [self.textView becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}


- (void)viewWillDisappear:(BOOL)animated {
    if (self.textView.text && self.textChanged) {
        self.content = self.textView.text;
        [self performSegueWithIdentifier:self.unwindIdentifier sender:nil];
    }
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


@end
