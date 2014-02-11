//
//  BUCCraftViewController.m
//  BUClient
//
//  Created by Joe Jeong on 2/1/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCEditorViewController.h"

@interface BUCEditorViewController ()
@property (weak, nonatomic) IBOutlet UITextView *content;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollview;
@property (weak, nonatomic) IBOutlet UITextField *subforum;
@property (weak, nonatomic) IBOutlet UITextField *subject;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@end

@implementation BUCEditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.subject becomeFirstResponder];
    
    CALayer *bottomBorderA = [CALayer layer];
    
    bottomBorderA.frame = CGRectMake(10.0f, 39.0f, 310.0f, 0.5f);
    
    bottomBorderA.backgroundColor = [UIColor colorWithWhite:0.8f
                                                     alpha:1.0f].CGColor;
    
    [self.scrollview.layer addSublayer:bottomBorderA];
    
    CALayer *bottomBorderB = [CALayer layer];
    
    bottomBorderB.frame = CGRectMake(10.0f, 79.0f, 310.0, 0.5f);
    
    bottomBorderB.backgroundColor = [UIColor colorWithWhite:0.8f
                                                     alpha:1.0f].CGColor;
    
    [self.scrollview.layer addSublayer:bottomBorderB];
    
	// Do any additional setup after loading the view.
}

- (IBAction)unwindToPrevious:(id)sender {
    [self performSegueWithIdentifier:self.unwindSegueIdendifier sender:nil];
}

#pragma mark - IBAction methods
- (IBAction)textFieldDidChanged:(UITextField *)textField {
    [self validateInputs];
}

#pragma mark - textfiled and textview delegate methods
- (void)textViewDidChange:(UITextView *)textView
{
    [self validateInputs];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - private methods
- (void)validateInputs
{
    if ([self.subforum.text length] && [self.subject.text length] && [self.content.text length]) {
        self.doneButton.enabled = YES;
    } else {
        self.doneButton.enabled = NO;
    }
}
@end



















