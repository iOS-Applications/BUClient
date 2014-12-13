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
    
    self.appDelegate = (BUCAppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.textChanged = NO;
    
    self.textView.text = self.content;
    self.textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.textView.layer.borderWidth = 0.5f;
    [self.textView becomeFirstResponder];
    if (![self.navigationItem.title isEqualToString:@"Signature"]) { 
        self.textView.selectedRange = NSMakeRange(0, 0);
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasHidden:) name:UIKeyboardDidHideNotification object:nil];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.textView resignFirstResponder];
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
    self.textViewBottomSpace.constant = kbSize.height + 8.0f;
}

- (void)keyboardWasHidden:(NSNotification*)notification {
    self.textViewBottomSpace.constant = 8.0f;
}


#pragma mark - text view delegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(range.length + range.location > textView.text.length) {
        return NO;
    }
    
    NSUInteger newLength = textView.text.length + text.length - range.length;
    if (newLength > self.lengthLimit) {
        [self.appDelegate alertWithMessage:[NSString stringWithFormat:@"%@字数不能超过%lu", self.navigationItem.title, (unsigned long)self.lengthLimit]];
        return NO;
    }
    
    return YES;
}


- (void)textViewDidChange:(UITextView *)textView {
    self.textChanged = YES;
}


@end
