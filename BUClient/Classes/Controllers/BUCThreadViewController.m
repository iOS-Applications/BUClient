
//
//  BUCThreadViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/14/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCThreadViewController.h"
#import "BUCAvatar.h"

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
    [self.avatarList removeObserver:self
                      fromObjectsAtIndexes:allindexes
                                forKeyPath:@"loadEnded"
                                   context:NULL];
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
    
    allindexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 20)];
    [self.avatarList addObserver:self
                     toObjectsAtIndexes:allindexes
                             forKeyPath:@"loadEnded"
                                options:NSKeyValueObservingOptionNew
                                context:NULL];

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
            [self urldecodeData];
            [self makeCacheList];
            if (self.loadImage) {
                NSString *avatarUrl = nil;
                NSInteger index = 0;
                BUCAvatar *avatar = nil;
                
                for (NSMutableDictionary *post in self.rawDataList) {
                    avatarUrl = [post objectForKey:@"avatar"];
                    avatar = [self.avatarList objectAtIndex:index];
                    // test code start
                    avatarUrl = @"http://0.0.0.0:8080/static/avatar.png";
                    // test code end
                    if ([avatarUrl length]) {
                        avatar.useDefaultAvatar = NO;
                        [self loadImage:avatarUrl atIndex:index];
                        // load image from internet
                    } else {
                        avatar.useDefaultAvatar = YES;
                        // load default avatar image
                    }
                    
                    index++;
                }
            }
            
            [self updateNavState];
            [self endLoading];
            [self.tableView reloadData];
        }
    } else if ([keyPath isEqualToString:@"loadEnded"]){
        BUCAvatar *avatar = (BUCAvatar *)object;
        if (!avatar.loadEnded) return;
        
        if (!avatar.error) {
            BUCTableCell *cell = (BUCTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:avatar.index inSection:0]];
            if (cell) cell.avatar.image = avatar.image;
        } else {
            // load default avatar image
        }
    }
}

- (void)urldecodeData
{
    for (NSMutableDictionary *item in self.rawDataList) {
        NSString *string = [[item objectForKey:@"author"] urldecode];
        [item setObject:string forKey:@"author"];
        string = [[item objectForKey:@"avatar"] urldecode];
        [item setObject:string forKey:@"avatar"];
        string = [[item objectForKey:@"message"] urldecode];
        [item setObject:string forKey:@"message"];
        string = [[item objectForKey:@"subject"] urldecode];
        [item setObject:string forKey:@"subject"];
    }
}

- (void)makeCacheList{
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *navVC = (UINavigationController *)segue.destinationViewController;
    BUCEditorViewController *editor = (BUCEditorViewController *)[navVC.childViewControllers lastObject];
    editor.unwindSegueIdendifier = self.unwindSegueIdentifier;
    editor.postSubject = self.thread.title;
}

#pragma mark - action methods
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
    
    [self loadData:self.subRequestDic];
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
    return [self.rawDataList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"threadCell";
    
    BUCTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    NSDictionary *post = [self.rawDataList objectAtIndex:indexPath.row];
    
    BUCAvatar *avatar = [self.avatarList objectAtIndex:indexPath.row];
    if (avatar.useDefaultAvatar) {
        // load default avatar
    } else if (avatar.loadEnded) {
        if (!avatar.error) {
            cell.avatar.image = avatar.image;
        } else {
            // load default avatar
        }
    }
    
    [cell.leftTopBtn setTitle:[post objectForKey:@"author"] forState:UIControlStateNormal];
    
    NSString *timestamp = [post objectForKey:@"dateline"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[timestamp integerValue]];
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [dateFormatter setLocale:locale];
    }
    
    UILabel *dateLabel = (UILabel *)[cell viewWithTag:3];
    dateLabel.text = [dateFormatter stringFromDate:date];
    
    UITextView *textview = (UITextView *)[cell viewWithTag:4];
    textview.text = [post objectForKey:@"subject"];
    
    textview = (UITextView *)[cell viewWithTag:5];
    textview.text = [post objectForKey:@"message"];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 185;
    NSDictionary *post = [self.rawDataList objectAtIndex:indexPath.row];
    NSString *text = [post objectForKey:@"subject"];
    CGRect frame = [text boundingRectWithSize:CGSizeMake(230, FLT_MAX)
                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                   attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]}
                                      context:nil];
    
    CGFloat padding = 10;
    
    return MAX(60, frame.size.height + padding) + 32; // 32 = 5(space between the bottom buttons and the title) + 27(height of button)
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
    
    self.pickerInputField.text = [NSString stringWithFormat:@"%i/%i", self.curPickerRow + 1, self.pageCount];
    [self.picker reloadComponent:0];
}

@end
