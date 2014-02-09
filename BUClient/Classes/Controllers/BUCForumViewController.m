//
//  BUCForumViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCForumViewController.h"
#import "BUCTableCell.h"

@interface BUCForumViewController ()
@property (strong, nonatomic) IBOutlet UITextField *pickerInputField;
@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (strong, nonatomic) IBOutlet UIToolbar *pickerToolbar;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelPicker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *donePicker;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *previous;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *next;

@property NSString *fid;
@property NSInteger postCount;
@property NSInteger pageCount;
@property NSInteger curPickerRow;

@property NSMutableDictionary *helpPostDic;
@property NSMutableDictionary *helpPostDataDic;
@end

@implementation BUCForumViewController

#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _helpPostDataDic = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)self.postDataDic];
        [_helpPostDataDic setObject:@"" forKey:@"tid"];
        _helpPostDic = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)self.postDic];
        [_helpPostDic setObject:_helpPostDataDic forKey:@"dataDic"];
        [_helpPostDic setObject:@"fid_tid" forKey:@"url"];
        
        [self.postDic setObject:@"thread" forKey:@"url"];
        [self.postDataDic setObject:@"thread" forKey:@"action"];
        [self.postDataDic setObject:@"0" forKey:@"from"];
        [self.postDataDic setObject:@"20" forKey:@"to"];
        self.listKey = @"threadlist";
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
    self.pickerInputField.delegate = self;
    
    UIBarButtonItem *tempBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.pickerInputField];
    NSMutableArray *items = [self.toolbarItems mutableCopy];
    [items insertObject:tempBarItem atIndex:5];
    [self setToolbarItems:items];
    
    NSDictionary *infoDic = self.contentController.infoDic;
    self.fid = [infoDic objectForKey:@"fid"];
    [self.postDataDic setObject:self.fid forKey:@"fid"];
    [self.helpPostDataDic setObject:self.fid forKey:@"fid"];
    self.postCount = [[infoDic objectForKey:@"postCount"] integerValue];
    self.pageCount = self.postCount % 20 ? self.postCount/20 + 1 : self.postCount/20;
    self.pickerInputField.text = [NSString stringWithFormat:@"1/%i", self.pageCount];
    self.navigationItem.title = [infoDic objectForKey:@"fname"];
    self.curPickerRow = 0;
    self.previous.enabled = NO;
    if (self.postCount <= 20) self.next.enabled = NO;
    
    [self loadData:self.postDic];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.responseDic) {
        NSString *temp = [self.responseDic objectForKey:@"fid_sum"];
        if (temp) {
            self.postCount = [temp integerValue];
            self.pageCount = self.postCount % 20 ? self.postCount/20 + 1 : self.postCount/20;
            self.pickerInputField.text = [NSString stringWithFormat:@"%i/%i", self.curPickerRow + 1, self.pageCount];
            [self updateNavState];
            [self.picker reloadComponent:0];
            [self loadData:self.postDic];
        } else {
            self.list = [self.responseDic objectForKey:self.listKey];
            [self endLoading];
            [self.tableView reloadData];
        }
    }
}

#pragma mark - action and unwind methods
- (IBAction)refresh:(id)sender
{
    if (self.loading || self.refreshing) return;
    
    if (![sender isKindOfClass:[UIRefreshControl class]]) {
        [self.contentController displayLoading];
        self.loading = YES;
        self.tableView.bounces = NO;
    } else {
        self.refreshing = YES;
    }
    
    [self loadData:self.helpPostDic];
}

- (IBAction)showActionSheet:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"发布新帖", @"返回首页", @"版面列表", nil];
    
    [actionSheet showInView:self.view];
}

- (IBAction)previous:(id)sender {
    if (self.loading || self.refreshing) [self cancelLoading];
    
    self.curPickerRow -= 1;
    [self.postDataDic setObject:[self.postDataDic objectForKey:@"from"] forKey:@"to"];
    [self.postDataDic setObject:[NSString stringWithFormat:@"%i", 20 * self.curPickerRow] forKey:@"from"];
    [self.picker selectRow:self.curPickerRow inComponent:0 animated:NO];
    
    [self refresh:nil];
}

- (IBAction)next:(id)sender {
    if (self.loading || self.refreshing) [self cancelLoading];
    
    self.curPickerRow += 1;
    [self.postDataDic setObject:[self.postDataDic objectForKey:@"to"] forKey:@"from"];
    [self.postDataDic setObject:[NSString stringWithFormat:@"%i", 20 * (self.curPickerRow + 1)] forKey:@"to"];
    [self.picker selectRow:self.curPickerRow inComponent:0 animated:NO];
    
    [self refresh:nil];
}

- (IBAction)donePagePick:(id)sender {
    [self.pickerInputField resignFirstResponder];
    if (self.loading || self.refreshing) [self cancelLoading];
    
    self.curPickerRow = [self.picker selectedRowInComponent:0];
    [self.postDataDic setObject:[NSString stringWithFormat:@"%i", 20 * self.curPickerRow] forKey:@"from"];
    [self.postDataDic setObject:[NSString stringWithFormat:@"%i", 20 * (self.curPickerRow + 1)] forKey:@"to"];
    
    [self refresh:nil];
}

- (IBAction)cancelPagePick:(id)sender {
    [self.pickerInputField resignFirstResponder];
    [self.picker selectRow:self.curPickerRow inComponent:0 animated:NO];
    if (self.loading || self.refreshing) [self resumeLoading];
}

- (IBAction)unwindToForum:(UIStoryboardSegue *)segue
{
    
}

#pragma  mark - table delegate and data source methods
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
    authorBtn.frame = CGRectMake(10, cellHeight - 27, size.width + 2, 27); // 2 is the width to compensate padding of button element
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

#pragma mark - picker view delegate/datasource methods

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"第%d页", row + 1];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.pageCount;
}

#pragma mark - text field delegate methods
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (self.loading || self.refreshing) [self suspendLoading];

    return YES;
}

#pragma mark - private methods
- (UIButton *)cellButtonWithTitle:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    
    return button;
}

- (void)updateNavState
{
    if (self.curPickerRow == 0) {
        self.previous.enabled = NO;
    } else {
        self.previous.enabled = YES;
    }
    
    if (self.curPickerRow == self.pageCount - 1) {
        self.next.enabled = NO;
    } else {
        self.next.enabled = YES;
    }
}

@end
