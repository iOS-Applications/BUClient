//
//  BUCForumViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCForumViewController.h"
#import "BUCTableCell.h"
#import "NSString+NSString_Extended.h"

@interface BUCForumViewController ()
@property (strong, nonatomic) IBOutlet UITextField *pickerInputField;
@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (strong, nonatomic) IBOutlet UIToolbar *pickerToolbar;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelPicker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *donePicker;

@property NSInteger threadCount;
@end

@implementation BUCForumViewController
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
        self.threadCount = 235695;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSBundle mainBundle] loadNibNamed:@"BUCPicker" owner:self options:nil];
    
    self.picker.frame = CGRectMake(0, 0, 320, 162);
    self.pickerInputField.inputView = self.picker;
    self.pickerInputField.inputAccessoryView = self.pickerToolbar;
    
    UIBarButtonItem *tempBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.pickerInputField];
    NSMutableArray *items = [self.toolbarItems mutableCopy];
    [items insertObject:tempBarItem atIndex:5];
    
    [self setToolbarItems:items];
    self.pickerInputField.text = @"第1页";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"forumCell";
    
    BUCTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    CGFloat cellHeight = cell.frame.size.height;
    NSDictionary *post = [self.list objectAtIndex:indexPath.row];
    
    [cell.replyCount setTitle:[post objectForKey:@"replies"] forState:UIControlStateNormal];
    
    CGRect frame = CGRectMake(0, 0, 230, cellHeight - 32);
    cell.title.frame = frame;
    cell.title.text = [[[post objectForKey:@"subject"] urldecode] replaceHtmlEntities];
    cell.title.font = [UIFont systemFontOfSize:18];
    
    
    NSDictionary *stringAttribute = @{NSFontAttributeName:[UIFont systemFontOfSize:15]};
    
    NSString *author = [[post objectForKey:@"author"] urldecode];
    UIButton *authorBtn = [self cellButtonWithTitle:author];
    
    CGSize size = [author sizeWithAttributes:stringAttribute];
    authorBtn.frame = CGRectMake(10, cellHeight - 27, size.width + 2, 27);      // 2 is the width to compensate padding of button element
    cell.authorBtn = authorBtn;
    [cell addSubview:authorBtn];
    
    NSString *timestamp = [post objectForKey:@"dateline"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[timestamp integerValue]];
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [dateFormatter setLocale:locale];
    }
    
    size = [timestamp sizeWithAttributes:stringAttribute];
    cell.timeStamp = [[UILabel alloc] initWithFrame:CGRectMake(180, cellHeight - 27, 140, 27)];
    cell.timeStamp.text = [dateFormatter stringFromDate:date];
    cell.timeStamp.font = [UIFont systemFontOfSize:15];
    [cell addSubview:cell.timeStamp];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *post = [self.list objectAtIndex:indexPath.row];
    NSString *text = [[post objectForKey:@"subject"] urldecode];
    CGRect frame = [text boundingRectWithSize:CGSizeMake(230, FLT_MAX)
                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                   attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]}
                                      context:nil];
    
    CGFloat padding = 10;
    
    return MAX(60, frame.size.height + padding) + 32; // 32 = 5(space between the bottom buttons and the title) + 27(height of button)
}

#pragma mark - action methods
- (IBAction)handlePagePick:(id)sender {
    [self.pickerInputField resignFirstResponder];
    self.pickerInputField.text = [NSString stringWithFormat:@"%i/%i", [self.picker selectedRowInComponent:0] + 1, self.threadCount];
}

- (IBAction)showActionSheet:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"发布新帖", @"返回首页", @"版面列表", nil];
    
    [actionSheet showInView:self.view];
}

#pragma mark - picker view delegate/datasource methods

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"第%d页", row + 1];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.threadCount;
}

#pragma mark - private methods
- (UIButton *)cellButtonWithTitle:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    
    return button;
}
@end
