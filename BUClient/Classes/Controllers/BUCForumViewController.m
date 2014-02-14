//
//  BUCForumViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCForumViewController.h"

@interface BUCForumViewController ()

@property (strong, nonatomic) IBOutlet UITextField *pickerInputField;
@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (strong, nonatomic) IBOutlet UIToolbar *pickerToolbar;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelPicker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *donePicker;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *previous;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *next;

@property (nonatomic) BUCForum *forum;
@property (nonatomic) NSInteger pageCount;
@property (nonatomic) NSInteger curPickerRow;

@property (nonatomic) NSMutableDictionary *subRequestDic;
@property (nonatomic) NSMutableDictionary *subJsonDic;

@end

@implementation BUCForumViewController

#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _subJsonDic = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)self.jsonDic];
        [_subJsonDic setObject:@"thread" forKey:@"action"];
        [_subJsonDic setObject:@"0" forKey:@"from"];
        [_subJsonDic setObject:@"20" forKey:@"to"];
        _subRequestDic = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)self.requestDic];
        [_subRequestDic setObject:_subJsonDic forKey:@"dataDic"];
        [_subRequestDic setObject:@"thread" forKey:@"url"];

        [self.requestDic setObject:@"fid_tid" forKey:@"url"];
        [self.jsonDic setObject:@"" forKey:@"tid"];
        
        self.rawListKey = @"threadlist";
        self.unwindSegueIdentifier = @"unwindToForum";
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
    
    self.forum = (BUCForum *)self.contentController.info;
    
    [self.jsonDic setObject:self.forum.fid forKey:@"fid"];
    [self.subJsonDic setObject:self.forum.fid forKey:@"fid"];
    
    self.navigationItem.title = self.forum.fname;
    
    self.previous.enabled = NO;
    self.next.enabled = NO;
    
    [self loadData:self.requestDic];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.rawDataDic) {
        NSInteger threadCount = [[self.rawDataDic objectForKey:@"fid_sum"] integerValue];
        if (threadCount) {
            self.forum.threadCount = threadCount;
            self.pageCount = threadCount % 20 ? threadCount/20 + 1 : threadCount/20;
            [self loadData:self.subRequestDic];
        } else {
            self.rawDataList = [self.rawDataDic objectForKey:self.rawListKey];
            [self makeCacheList];
            
            [self updateNavState];
            
            [self endLoading];
            [self.tableView reloadData];
        }
    }
}

- (void)makeCacheList
{
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [dateFormatter setLocale:locale];
    }
    
    static NSString *authorKey = @"author";
    static NSString *tidKey = @"tid";
    static NSString *subjectKey = @"subject";
    static NSString *repliesKey = @"replies";
    static NSString *datelineKey = @"dateline";
    
    BUCThread *thread = nil;
    for (NSDictionary *rawThread in self.rawDataList) {
        thread = [[BUCThread alloc] init];
        thread.forum = self.forum;
        thread.poster = [[BUCPoster alloc] init];
        thread.poster.username = [[rawThread objectForKey:authorKey] urldecode];
        thread.tid = [rawThread objectForKey:tidKey];
        thread.title = [[[rawThread objectForKey:subjectKey] urldecode] replaceHtmlEntities];
        thread.replyCount = [rawThread objectForKey:repliesKey];
        thread.dateline = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[rawThread objectForKey:datelineKey] integerValue]]];
        
        [self.dataList addObject:thread];
        [self.cellList addObject:[self createCellWithThread:thread]];
    }
}

#pragma mark - action and unwind methods
- (IBAction)jumpToPoster:(id)sender forEvent:(UIEvent *)event {
    [self.indexController deselectCurrentRow];
    self.contentController.info = ((BUCThread *)[self.dataList objectAtIndex:[self getRowOfEvent:event]]).poster;
    [self performSegueWithIdentifier:@"segueToUser" sender:nil];
}

- (IBAction)jumpToThread:(id)sender forEvent:(UIEvent *)event {
    [self.indexController deselectCurrentRow];
    self.contentController.info = [self.dataList objectAtIndex:[self getRowOfEvent:event]];
    [self.contentController performSegueWithIdentifier:@"segueToThread" sender:nil];
}
- (IBAction)showActionSheet:(id)sender {
    if (self.loading || self.refreshing) [self suspendLoading];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"发布新帖", @"返回首页", @"版块列表", @"返回顶部", nil];
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self performSegueWithIdentifier:@"segueToEditor" sender:nil];
            break;
            
        case 1:
            [self.contentController performSegueWithIdentifier:@"segueToFront" sender:nil];
            break;

        case 2:
            [self.contentController performSegueWithIdentifier:@"segueToForumList" sender:nil];
            break;
            
        case 3:
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            break;
            
        default:
            if (self.loading || self.refreshing) [self resumeLoading];
            break;
    }
}

- (IBAction)previous:(id)sender {
    if (self.loading || self.refreshing) [self cancelLoading];
    
    self.curPickerRow -= 1;
    [self.jsonDic setObject:[self.jsonDic objectForKey:@"from"] forKey:@"to"];
    [self.jsonDic setObject:[NSString stringWithFormat:@"%i", 20 * self.curPickerRow] forKey:@"from"];
    [self.picker selectRow:self.curPickerRow inComponent:0 animated:NO];
    
    [self refresh:nil];
}

- (IBAction)next:(id)sender {
    if (self.loading || self.refreshing) [self cancelLoading];
    
    self.curPickerRow += 1;
    [self.jsonDic setObject:[self.jsonDic objectForKey:@"to"] forKey:@"from"];
    [self.jsonDic setObject:[NSString stringWithFormat:@"%i", 20 * (self.curPickerRow + 1)] forKey:@"to"];
    [self.picker selectRow:self.curPickerRow inComponent:0 animated:NO];
    
    [self refresh:nil];
}

- (IBAction)donePagePick:(id)sender {
    [self.pickerInputField resignFirstResponder];
    
    if (self.pageCount == 0) { // page picker is activated before first load ended, so nothing should be done, just resume and return
        if (self.loading || self.refreshing) [self resumeLoading];
        return;
    }
    
    self.curPickerRow = [self.picker selectedRowInComponent:0];
    
    if (self.loading || self.refreshing) [self cancelLoading];
    
    [self.jsonDic setObject:[NSString stringWithFormat:@"%i", 20 * self.curPickerRow] forKey:@"from"];
    [self.jsonDic setObject:[NSString stringWithFormat:@"%i", 20 * (self.curPickerRow + 1)] forKey:@"to"];
    
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
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.cellList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.cellList objectAtIndex:indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ((BUCTableCell *)[self.cellList objectAtIndex:indexPath.row]).height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.indexController deselectCurrentRow];
    self.contentController.info = [self.dataList objectAtIndex:indexPath.row];
    [self.contentController performSegueWithIdentifier:@"segueToThread" sender:nil];
}

#pragma mark - picker view delegate/datasource methods

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    static NSString  *formatString = @"第%d页";
    return [NSString stringWithFormat:formatString, row + 1];
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
    if (self.pageCount == 0) return  NO;
    
    if (self.loading || self.refreshing) [self suspendLoading];

    return YES;
}

#pragma mark - private methods
- (UIButton *)cellButtonWithTitle:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:15];
    
    return button;
}

- (NSInteger)getRowOfEvent:(UIEvent *)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self.tableView];
    return [self.tableView indexPathForRowAtPoint:p].row;
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
    
    self.pickerInputField.text = [NSString stringWithFormat:@"%i/%i", self.curPickerRow + 1, self.pageCount];
    [self.picker reloadComponent:0];
}

- (CGFloat)calculateHeightForText:(NSString *)text
{
    CGRect frame = [text boundingRectWithSize:CGSizeMake(250, FLT_MAX)
                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                   attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]}
                                      context:nil];
    
    CGFloat padding = 10;
    
    return MAX(60, frame.size.height + padding) + 32; // 32 = 5(space between the bottom buttons and the title) + 27(height of button)
}

- (BUCTableCell *)createCellWithThread:(BUCThread *)thread
{
    static NSString *CellIdentifier = @"forumCell";
    
    BUCTableCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.height = [self calculateHeightForText:thread.title];
    
    [cell.replyCount setTitle:thread.replyCount forState:UIControlStateNormal];
    
    CGRect frame = CGRectMake(0, 0, 250, cell.height - 32);
    cell.title.frame = frame;
    cell.title.text = thread.title;
    cell.title.font = [UIFont systemFontOfSize:18];
    
    NSDictionary *stringAttribute = @{NSFontAttributeName:[UIFont systemFontOfSize:15]};
    
    UIButton *leftBottomBtn = [self cellButtonWithTitle:thread.poster.username];
    CGSize size = [thread.poster.username sizeWithAttributes:stringAttribute];
    leftBottomBtn.frame = CGRectMake(10, cell.height - 27, size.width + 2, 27); // 2 is the width to compensate padding of button element
    [leftBottomBtn addTarget:self action:@selector(jumpToPoster:forEvent:) forControlEvents:UIControlEventTouchUpInside];
    cell.leftBottomBtn = leftBottomBtn;
    [cell addSubview:leftBottomBtn];
    
    size = [thread.dateline sizeWithAttributes:stringAttribute];
    UILabel *timeStamp = [[UILabel alloc] initWithFrame:CGRectMake(180, cell.height - 27, 140, 27)];
    timeStamp.text = thread.dateline;
    timeStamp.font = [UIFont fontWithName:@"Helvetica-Light" size:15];
    cell.timeStamp = timeStamp;
    [cell addSubview:timeStamp];
    
    return cell;
}
@end
