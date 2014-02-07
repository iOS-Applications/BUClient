//
//  BUCThreadViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/14/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCThreadViewController.h"
#import "BUCMainViewController.h"

@interface BUCThreadViewController ()

@property (strong, nonatomic) IBOutlet UITextField *pickerInputField;
@property (strong, nonatomic) IBOutlet UIPickerView *picker;

@property (strong, nonatomic) IBOutlet UIToolbar *pickerToolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelPicker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *donePicker;

@property NSInteger postCount;
@end

@implementation BUCThreadViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self.postDic setObject:@"thread" forKey:@"url"];
        [self.postDataDic setObject:@"thread" forKey:@"action"];
        [self.postDataDic setObject:@"32" forKey:@"fid"];
        [self.postDataDic setObject:@"0" forKey:@"from"];
        [self.postDataDic setObject:@"20" forKey:@"to"];
        self.listKey = @"threadlist";
        self.postCount = 235695;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSBundle mainBundle] loadNibNamed:@"ThreadPagePicker" owner:self options:nil];
    
    self.picker.frame = CGRectMake(0, 0, 320, 162);
    self.pickerInputField.inputView = self.picker;
    self.pickerInputField.inputAccessoryView = self.pickerToolbar;
    
    UIBarButtonItem *tempBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.pickerInputField];
    NSMutableArray *items = [self.toolbarItems mutableCopy];
    [items insertObject:tempBarItem atIndex:5];
    
    [self setToolbarItems:items];
    
    
}

#pragma mark - action methods
- (IBAction)handlePagePick:(id)sender {
    [self.pickerInputField resignFirstResponder];
    self.pickerInputField.text = [NSString stringWithFormat:@"%i/%i", [self.picker selectedRowInComponent:0] + 1, self.postCount];
}

- (IBAction)showActionSheet:(id)sender {
    UIActionSheet *threadActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                     destructiveButtonTitle:nil
                                                          otherButtonTitles:@"发布新帖", @"返回版面", nil];
    
    [threadActionSheet showInView:self.view];
}

#pragma mark - picker view delegate/datasource methods

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"第%d页", row];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.postCount;
}

@end
