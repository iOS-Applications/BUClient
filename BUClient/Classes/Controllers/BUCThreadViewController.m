
//
//  BUCThreadViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/14/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCThreadViewController.h"
#import "BUCAvatar.h"

static NSString *fontKey = @"Helvetica-Light";

@interface BUCThreadViewController ()
{
    NSIndexSet *allindexes;
}

@property (strong, nonatomic) IBOutlet UITextField *pickerInputField;
@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (strong, nonatomic) IBOutlet UIToolbar *pickerToolbar;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelPicker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *donePicker;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *previous;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *next;

@property (nonatomic) BUCForum *forum;
@property (nonatomic) BUCThread *thread;
@property (nonatomic) NSInteger pageCount;
@property (nonatomic) NSInteger curPickerRow;

@property (nonatomic) NSMutableDictionary *subRequestDic;
@property (nonatomic) NSMutableDictionary *subJsonDic;

@property (nonatomic) BOOL loadImage;
@property (nonatomic) UIImage *defaultAvatar;
@end

@implementation BUCThreadViewController
#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _subJsonDic = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)self.jsonDic];
        _subRequestDic = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)self.requestDic];
        [_subJsonDic setObject:@"post" forKey:@"action"];
        [_subJsonDic setObject:@"0" forKey:@"from"];
        [_subJsonDic setObject:@"20" forKey:@"to"];
        [_subRequestDic setObject:_subJsonDic forKey:@"dataDic"];
        [_subRequestDic setObject:@"post" forKey:@"url"];
        
        [self.requestDic setObject:@"fid_tid" forKey:@"url"];
        [self.jsonDic setObject:@"" forKey:@"fid"];
        
        self.rawListKey = @"postlist";
        self.unwindSegueIdentifier = @"unwindToThread";
        
        _loadImage = [self.user.loadImage isEqualToString:@"yes"] ? YES : NO;
    }
    
    return self;
}

- (void)dealloc
{
    if (self.loadImage) {
        [self.avatarList removeObserver:self
                   fromObjectsAtIndexes:allindexes
                             forKeyPath:@"loadEnded"
                                context:NULL];
    }
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
    
    self.thread = (BUCThread *)self.contentController.info;
    self.forum = self.thread.forum;
    
    [self.jsonDic setObject:self.thread.tid forKey:@"tid"];
    [self.subJsonDic setObject:self.thread.tid forKey:@"tid"];

    self.navigationItem.title = self.thread.title;

    self.previous.enabled = NO;
    self.next.enabled = NO;
    
    if (self.loadImage) {
        self.defaultAvatar = [UIImage imageNamed:@"avatar.png"];
        allindexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 20)];
        [self.avatarList addObserver:self
                  toObjectsAtIndexes:allindexes
                          forKeyPath:@"loadEnded"
                             options:NSKeyValueObservingOptionNew
                             context:NULL];
    }

    [self loadData:self.requestDic];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"rawDataDic"] && self.rawDataDic) {
        NSInteger postCount = [[self.rawDataDic objectForKey:@"tid_sum"] integerValue];
        if (postCount) {
            self.thread.postCount = postCount;
            self.pageCount = postCount % 20 ? postCount/20 + 1 : postCount/20;
            [self loadData:self.subRequestDic];
        } else {
            self.rawDataList = [self.rawDataDic objectForKey:self.rawListKey];
            [self makeCacheList];
            [self updateNavState];
            [self endLoading];
            [self.tableView reloadData];
        }
    } else if ([keyPath isEqualToString:@"loadEnded"]) {
        BUCAvatar *avatar = (BUCAvatar *)object;
        if (!avatar.loadEnded) return;
        
        if (!avatar.error) {
            ((BUCTableCell *)[self.cellList objectAtIndex:avatar.index]).avatar.image = avatar.image;
        } else {
            // load default avatar image
        }
    }
}

- (void)makeCacheList{
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [dateFormatter setLocale:locale];
    }
    
    static NSString *authorKey = @"author";
    static NSString *avatarKey = @"avatar";
    static NSString *messageKey = @"message";
    static NSString *subjectKey = @"subject";
    static NSString *datelineKey = @"dateline";
    
    BUCPost *post = nil;
    NSInteger index = 0;
    for (NSMutableDictionary *rawPost in self.rawDataList) {
        post = [[BUCPost alloc] init];
        post.thread = self.thread;
        post.poster = [[BUCPoster alloc] init];
        post.poster.username = [[rawPost objectForKey:authorKey] urldecode];
        post.poster.avatarUrl = [[rawPost objectForKey:avatarKey] urldecode];
        post.message = [[rawPost objectForKey:messageKey] urldecode];
        post.title = [[rawPost objectForKey:subjectKey] urldecode];
        post.dateline = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[rawPost objectForKey:datelineKey] integerValue]]];
        post.index = index;
        [self.dataList addObject:post];
        [self.cellList addObject:[self createCellForPost:post]];
        index++;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *navVC = (UINavigationController *)segue.destinationViewController;
    BUCEditorViewController *editor = (BUCEditorViewController *)[navVC.childViewControllers lastObject];
    editor.unwindSegueIdendifier = self.unwindSegueIdentifier;
    editor.postSubject = self.thread.title;
}

#pragma mark - action methods
- (IBAction)jumpToPoster:(id)sender forEvent:(UIEvent *)event {
    [self.indexController deselectCurrentRow];
    self.contentController.info = ((BUCThread *)[self.dataList objectAtIndex:[self getRowOfEvent:event]]).poster;
    [self performSegueWithIdentifier:@"segueToUser" sender:nil];
}

- (IBAction)showActionSheet:(id)sender {
    if (self.loading || self.refreshing) [self suspendLoading];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"回复本帖", @"返回首页", @"返回版面", @"返回顶部", nil];
    
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
            self.contentController.info = self.forum;
            [self.contentController performSegueWithIdentifier:@"segueToForum" sender:nil];
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

- (IBAction)unwindToThread:(UIStoryboardSegue *)segue
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

#pragma mark - picker view delegate/datasource methods
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    static NSString *formatString = @"第%d页";
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
- (NSInteger)getRowOfEvent:(UIEvent *)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self.tableView];
    return [self.tableView indexPathForRowAtPoint:p].row;
}

- (UIButton *)cellButtonWithTitle:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:fontKey size:15];
    
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
    
    self.pickerInputField.text = [NSString stringWithFormat:@"%i/%i", self.curPickerRow + 1, self.pageCount];
    [self.picker reloadComponent:0];
}

- (BUCTableCell *)createCellForPost:(BUCPost *)post
{
    static NSString *CellIdentifier = @"threadCell";
    static NSString *quoteKey = @"引用";
    static NSString *indexKey = @"%d楼";
    static NSString *testurlKey = @"http://0.0.0.0:8080/static/avatar.png"; // just for test
    
    BUCTableCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    // configure user button
    NSDictionary *stringAttribute = @{NSFontAttributeName:[UIFont systemFontOfSize:15]};
    UIButton *leftTopBtn = [self cellButtonWithTitle:post.poster.username];
    CGSize size = [post.poster.username sizeWithAttributes:stringAttribute];
    leftTopBtn.frame = CGRectMake(5, 5, size.width + 2, 20); // 2 is the width to compensate padding of button element
    [leftTopBtn addTarget:self action:@selector(jumpToPoster:forEvent:) forControlEvents:UIControlEventTouchUpInside];
    cell.leftTopBtn = leftTopBtn;
    [cell addSubview:leftTopBtn];
    
    // configure post index
    cell.postIndex.text = [NSString stringWithFormat:indexKey, post.index + 1];

    // configure avatar
    if (self.loadImage) {
        // test code start
        post.poster.avatarUrl = testurlKey;
        // test code end
        if ([post.poster.avatarUrl length]) {
            [self loadImage:post.poster.avatarUrl atIndex:post.index];
        } else {
            cell.avatar.image = self.defaultAvatar;
        }
    }
    // configure message content
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    UIWebView *content = [[UIWebView alloc] initWithFrame:CGRectMake(80, 25, 240, 200)];
    content.scrollView.scrollEnabled = NO;
    content.paginationMode = UIWebPaginationModeTopToBottom;
    [content loadHTMLString:post.message baseURL:baseURL];
    cell.content = content;
    [cell addSubview:content];
    
    // configure dateline
    UILabel *timeStamp = [[UILabel alloc] initWithFrame:CGRectMake(5, 220, 140, 20)];
    timeStamp.text = post.dateline;
    timeStamp.font = [UIFont fontWithName:fontKey size:15];
    cell.timeStamp = timeStamp;
    [cell addSubview:timeStamp];
    
    // configure quote button

    UIButton *quoteBtn = [self cellButtonWithTitle:quoteKey];
    quoteBtn.frame = CGRectMake(275, 220, 40, 20);
    quoteBtn.titleLabel.font = [UIFont fontWithName:fontKey size:15];
    cell.rightBottomBtn = quoteBtn;
    [cell addSubview:quoteBtn];
    
    cell.height = 240;
    
    return cell;
}

@end
