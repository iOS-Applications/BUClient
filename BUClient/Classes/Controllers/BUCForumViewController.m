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
@property (nonatomic) NSInteger curPickerRow;

@property (nonatomic) BUCTask *navTask;
@end

@implementation BUCForumViewController

#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _navTask = [[BUCTask alloc] init];
        _navTask.index = 1;
        _navTask.json = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)self.task.json];
        [_navTask.json setObject:@"" forKey:@"tid"];
        _navTask.url = @"fid_tid";
        _navTask.silence = NO;
        [self.taskList addObject:_navTask];
        
        [self.task.json setObject:@"thread" forKey:@"action"];
        [self.task.json setObject:@"0" forKey:@"from"];
        [self.task.json setObject:@"20" forKey:@"to"];
        [self.task.json setObject:@"" forKey:@"tid"];
        self.task.url = @"thread";
        
        self.jsonListKey = @"threadlist";
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
    
    [self.task.json setObject:self.forum.fid forKey:@"fid"];
    [self.navTask.json setObject:self.forum.fid forKey:@"fid"];
    
    self.navigationItem.title = self.forum.fname;
    
    self.previous.enabled = NO;
    self.next.enabled = NO;
    
    [self.navTask addObserver:self forKeyPath:@"jsonData" options:NSKeyValueObservingOptionNew context:NULL];
    [self startAllTasks];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    BUCTask *task = (BUCTask *)object;
    BUCTask *subtask = nil;
    NSDictionary *jsonData = task.jsonData;
    
    if (task.index == 1) {
        NSInteger threadCount = [[jsonData objectForKey:@"fid_sum"] integerValue];
        self.forum.threadCount = threadCount;
        self.pageCount = threadCount % 20 ? threadCount/20 + 1 : threadCount/20;
        task.done = YES;
        subtask = [self.taskList objectAtIndex:1];
        if (subtask.done) [self updateUI];
    } else {
        [self makeCacheList];
        task.done = YES;
        subtask = [self.taskList objectAtIndex:0];
        if (subtask.done) [self updateUI];
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
    
    BUCTask *task = self.task;
    NSArray *jsonDataList = [task.jsonData objectForKey:self.jsonListKey];
    BUCThread *thread = nil;
    NSMutableArray *dataList = [[NSMutableArray alloc] init];
    NSMutableArray *cellList = [[NSMutableArray alloc] init];
    for (NSDictionary *rawThread in jsonDataList) {
        thread = [[BUCThread alloc] init];
        thread.forum = self.forum;
        thread.poster = [[BUCPoster alloc] init];
        thread.poster.username = [[rawThread objectForKey:authorKey] urldecode];
        thread.tid = [rawThread objectForKey:tidKey];
        thread.title = [[[rawThread objectForKey:subjectKey] urldecode] replaceHtmlEntities];
        thread.replyCount = [rawThread objectForKey:repliesKey];
        thread.dateline = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[rawThread objectForKey:datelineKey] integerValue]]];
        
        [dataList addObject:thread];
        [cellList addObject:[self createCellWithThread:thread]];
    }
    self.dataList = dataList;
    self.cellList = cellList;
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
    [self.navTask.json setObject:[self.navTask.json objectForKey:@"from"] forKey:@"to"];
    [self.navTask.json setObject:[NSString stringWithFormat:@"%i", 20 * self.curPickerRow] forKey:@"from"];
    [self.picker selectRow:self.curPickerRow inComponent:0 animated:NO];
    
    [self refresh:nil];
}

- (IBAction)next:(id)sender {
    if (self.loading || self.refreshing) [self cancelLoading];
    
    self.curPickerRow += 1;
    [self.navTask.json setObject:[self.navTask.json objectForKey:@"to"] forKey:@"from"];
    [self.navTask.json setObject:[NSString stringWithFormat:@"%i", 20 * (self.curPickerRow + 1)] forKey:@"to"];
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
    
    [self.navTask.json setObject:[NSString stringWithFormat:@"%i", 20 * self.curPickerRow] forKey:@"from"];
    [self.navTask.json setObject:[NSString stringWithFormat:@"%i", 20 * (self.curPickerRow + 1)] forKey:@"to"];
    
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
- (void)updateUI
{
    [self endLoading];
    [self updateNavState];
    [self.tableView reloadData];
}

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
