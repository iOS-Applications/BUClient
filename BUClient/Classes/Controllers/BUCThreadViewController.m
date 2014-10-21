
//
//  BUCThreadViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/14/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCThreadViewController.h"
#import "BUCHTMLParser.h"

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

@property (nonatomic) BUCTask *navTask;
@property (nonatomic) BUCTask *profileTask;
@property (nonatomic) BUCTask *avatarTask;

@property (nonatomic) BOOL loadImage;

@property (nonatomic) BUCHTMLParser *parser;
@end

@implementation BUCThreadViewController
#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _navTask = [[BUCTask alloc] init];
        _navTask.json = [NSMutableDictionary dictionaryWithDictionary:self.task.json];
        [_navTask.json setObject:@"" forKey:@"fid"];
        _navTask.url = @"fid_tid";
        _navTask.index = 1;
        _navTask.silence = NO;
        [self.taskList addObject:_navTask];

        _profileTask = [[BUCTask alloc] init];
        _profileTask.taskList = [[NSMutableArray alloc] init];
        
        _avatarTask = [[BUCTask alloc] init];
        _avatarTask.taskList = [[NSMutableArray alloc] init];
        
        _profileTask.json = [NSMutableDictionary dictionaryWithDictionary:self.task.json];
        NSMutableDictionary *profileJson = [NSMutableDictionary dictionaryWithDictionary:self.task.json];
        [profileJson setObject:@"profile" forKey:@"action"];
        static NSString *profileUrl = @"profile";
        BUCTask *task = nil;
        for (int i = 0; i < 20; ++i) {
            task = [[BUCTask alloc] init];
            task.url = profileUrl;
            task.json = profileJson;
            task.index = i;
            task.silence = YES;
            [_profileTask.taskList addObject:task];
            
            task = [[BUCTask alloc] init];
            task.index = i;
            task.silence = YES;
            [_avatarTask.taskList addObject:task];
        }
        
        [self.taskList addObject:_profileTask];
        [self.taskList addObject:_avatarTask];
        
        [self.task.json setObject:@"post" forKey:@"action"];
        [self.task.json setObject:@"0" forKey:@"from"];
        [self.task.json setObject:@"20" forKey:@"to"];
        self.task.url = @"post";
        
        self.jsonListKey = @"postlist";
        self.unwindSegueIdentifier = @"unwindToThread";
        
        _loadImage = [self.user.loadImage isEqualToString:@"yes"] ? YES : NO;
        
        _parser = [BUCHTMLParser sharedInstance];
    }
    
    return self;
}

- (void)dealloc
{
    [self.profileTask.taskList removeObserver:self
                         fromObjectsAtIndexes:allindexes
                                   forKeyPath:@"jsonData"
                                      context:NULL];
    
    [self.avatarTask.taskList removeObserver:self
                        fromObjectsAtIndexes:allindexes
                                  forKeyPath:@"data"
                                     context:NULL];
    
    for (BUCTableCell *cell in self.cellList) {
        cell.content.delegate = nil;
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
    
    [self.task.json setObject:self.thread.tid forKey:@"tid"];
    [self.navTask.json setObject:self.thread.tid forKey:@"tid"];

    self.navigationItem.title = self.thread.title;

    self.previous.enabled = NO;
    self.next.enabled = NO;

    allindexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 20)];
    [self.navTask addObserver:self forKeyPath:@"jsonData" options:NSKeyValueObservingOptionNew context:NULL];
    
    // ad hoc kvo start
    [self.profileTask addObserver:self forKeyPath:@"jsonData" options:NSKeyValueObservingOptionNew context:NULL];
    [self.avatarTask addObserver:self forKeyPath:@"jsonData" options:NSKeyValueObservingOptionNew context:NULL];
    // ad hoc kvo end
    
    [self.profileTask.taskList addObserver:self
                        toObjectsAtIndexes:allindexes
                                forKeyPath:@"jsonData"
                                   options:NSKeyValueObservingOptionNew
                                   context:NULL];

    [self.avatarTask.taskList addObserver:self
                       toObjectsAtIndexes:allindexes
                               forKeyPath:@"data"
                                  options:NSKeyValueObservingOptionNew
                                  context:NULL];

    [self startAllTasks];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    BUCTask *task = (BUCTask *)object;
    if ([keyPath isEqualToString:@"jsonData"]) {
        NSDictionary *jsonData = task.jsonData;
        
        // mother fucking temporary credit solution
        if (task.silence) {
            if (task.index >= [self.cellList count]) return;
            
            BUCTableCell *cell = [self.cellList objectAtIndex:task.index];
            static NSString *formatKey = @"积分: %@";
            static NSString *memberinfoKey = @"memberinfo";
            static NSString *creditKey = @"credit";
            cell.credit.text = [NSString stringWithFormat:formatKey, [[jsonData objectForKey:memberinfoKey] objectForKey:creditKey]];
            return;
        }
        // mother fucking temporary credit solution end
        
        if (task.index == 1) {
            NSInteger postCount = [[jsonData objectForKey:@"tid_sum"] integerValue] + 1;
            self.thread.postCount = postCount;
            self.pageCount = postCount % 20 ? postCount/20 + 1 : postCount/20;
            task.done = YES;
            task = self.task;
            if (task.done) [self updateUI];
        } else {
            [self makeCacheList];
            task.done = YES;
            task = self.navTask;
            if (task.done) [self updateUI];
        }
    } else {
        BUCTableCell *cell = [self.cellList objectAtIndex:task.index];
        cell.avatar.image = [UIImage imageWithData:task.data];
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
    static NSString *uidKey = @"uid";
    static NSString *queryusernameKey = @"queryusername";
    
    BUCTask *task = self.task;
    NSArray *jsonDataList = [task.jsonData objectForKey:self.jsonListKey];
    BUCPostOld *post = nil;
    NSInteger index = 0;
    NSMutableArray *dataList = [[NSMutableArray alloc] init];
    NSMutableArray *cellList = [[NSMutableArray alloc] init];
    for (NSMutableDictionary *rawPost in jsonDataList) {
        post = [[BUCPostOld alloc] init];
        post.thread = self.thread;
        post.poster = [[BUCPoster alloc] init];
        post.poster.username = [[rawPost objectForKey:authorKey] urldecode];
        post.poster.uid = [rawPost objectForKey:uidKey];
        
        // mother fucking temporary solution start
        BUCTask *profileTask = [self.profileTask.taskList objectAtIndex:index];
        [profileTask.json setObject:post.poster.uid forKey:uidKey];
        [profileTask.json setObject:post.poster.username forKey:queryusernameKey];
        [self loadJSONOfTask:profileTask];
        // mother fucking temporary solution end
        
        post.poster.avatarUrl = [[rawPost objectForKey:avatarKey] urldecode];
        BUCTask *avatarTask = [self.avatarTask.taskList objectAtIndex:index];
        avatarTask.url = post.poster.avatarUrl;
        if (self.loadImage) [self loadDataOfTask:avatarTask];
        
        post.message = [self.parser parse:[[rawPost objectForKey:messageKey] urldecode]];
        post.title = [[rawPost objectForKey:subjectKey] urldecode];
        post.dateline = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[rawPost objectForKey:datelineKey] integerValue]]];
        post.index = index;
        [dataList addObject:post];
        [cellList addObject:[self createCellForPost:post]];
        index++;
    }
    
    self.dataList = dataList;
    self.cellList = cellList;
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
    if (self.loading || self.refreshing) {
        [self cancelLoading];
        [self updateNavState];
    }
    
    if (self.curPickerRow > 0) self.curPickerRow -= 1;
    
    [self updateNavState];
    [self.task.json setObject:[self.task.json objectForKey:@"from"] forKey:@"to"];
    [self.task.json setObject:[NSString stringWithFormat:@"%li", 20 * self.curPickerRow] forKey:@"from"];
    [self.picker selectRow:self.curPickerRow inComponent:0 animated:NO];
    
    [self refresh:nil];
}

- (IBAction)next:(id)sender {
    if (self.loading || self.refreshing) {
        [self cancelLoading];
        [self updateNavState];
    }
    
    if (self.curPickerRow < self.pageCount - 1) {
        self.curPickerRow += 1;
        [self.task.json setObject:[self.task.json objectForKey:@"to"] forKey:@"from"];
        [self.task.json setObject:[NSString stringWithFormat:@"%li", 20 * (self.curPickerRow + 1)] forKey:@"to"];
        [self.picker selectRow:self.curPickerRow inComponent:0 animated:NO];
    }
    
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
    
    [self.task.json setObject:[NSString stringWithFormat:@"%li", 20 * self.curPickerRow] forKey:@"from"];
    [self.task.json setObject:[NSString stringWithFormat:@"%li", 20 * (self.curPickerRow + 1)] forKey:@"to"];
    
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
- (void)updateUI
{
    [self endLoading];
    [self updateNavState];
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:NSNotFound inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

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
    
    self.pickerInputField.text = [NSString stringWithFormat:@"%li/%li", self.curPickerRow + 1, (long)self.pageCount];
    [self.picker reloadComponent:0];
}

- (BUCTableCell *)createCellForPost:(BUCPostOld *)post
{
    static NSString *CellIdentifier = @"threadCell";
    static NSString *quoteKey = @"引用";
    static NSString *indexKey = @"%d楼";
    
    BUCTableCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    // configure user button
    NSDictionary *stringAttribute = @{NSFontAttributeName:[UIFont systemFontOfSize:15]};
    UIButton *leftTopBtn = [self cellButtonWithTitle:post.poster.username];
    CGSize size = [post.poster.username sizeWithAttributes:stringAttribute];
    leftTopBtn.frame = CGRectMake(65, 5, size.width + 2, 20); // 2 is the width to compensate padding of button element
    [leftTopBtn addTarget:self action:@selector(jumpToPoster:forEvent:) forControlEvents:UIControlEventTouchUpInside];
    cell.leftTopBtn = leftTopBtn;
    [cell addSubview:leftTopBtn];
    
    // configure post index
    cell.postIndex.text = [NSString stringWithFormat:indexKey, post.index + self.curPickerRow * 20 + 1];
    
    // configure message content
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    UIWebView *content = [[UIWebView alloc] initWithFrame:CGRectMake(0, 60, 320, 0.01)];
    content.scrollView.scrollEnabled = NO;
    content.dataDetectorTypes = UIDataDetectorTypeNone;
    content.delegate = self;
    [content loadHTMLString:post.message baseURL:baseURL];
    cell.content = content;
    [cell addSubview:content];
    
    // configure dateline
    cell.dateline.text = post.dateline;
    
    // configure quote button
    UIButton *quoteBtn = [self cellButtonWithTitle:quoteKey];
    quoteBtn.frame = CGRectMake(275, 220, 40, 20);
    quoteBtn.titleLabel.font = [UIFont fontWithName:fontKey size:15];
    cell.rightBottomBtn = quoteBtn;
    [cell addSubview:quoteBtn];
    
    cell.height = 150;
    
    return cell;
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    static NSString *jsString = @"document.body.scrollHeight;";
    NSInteger tempHeight = [[webView stringByEvaluatingJavaScriptFromString:jsString] integerValue];
    NSInteger height;
    
    while (YES) {
        height = [[webView stringByEvaluatingJavaScriptFromString:jsString] integerValue];
        if (height == tempHeight) break;
        tempHeight = height;
    }
    // oddly, result of first calculation may be incorrect. maybe it's because webview doesn't finish loading
    
    BUCTableCell *cell = (BUCTableCell *)webView.superview.superview;
    cell.height = 60 + height + 30;
    cell.content.frame = CGRectMake(0, 60, 320, height);
    cell.rightBottomBtn.frame = CGRectMake(270, cell.height - 25, 40, 20);
    [self.tableView reloadData];
}
@end
