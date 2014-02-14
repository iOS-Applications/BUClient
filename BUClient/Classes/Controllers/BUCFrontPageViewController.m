//
//  BUCFrontPageViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCFrontPageViewController.h"

@implementation BUCFrontPageViewController
#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self.requestDic setObject:@"home" forKey:@"url"];
        self.rawListKey = @"newlist";
        self.unwindSegueIdentifier = @"unwindToFront";
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadData:self.requestDic];
}

- (void)makeCacheList
{
    BUCThread *thread = nil;
    for (NSDictionary *rawThread in self.rawDataList) {
        thread = [[BUCThread alloc] init];
        thread.poster = [[BUCPoster alloc] init];
        thread.poster.username = [[rawThread objectForKey:@"author"] urldecode];
        thread.forum = [[BUCForum alloc] init];
        thread.forum.fid = [rawThread objectForKey:@"fid"];
        thread.forum.fname = [[rawThread objectForKey:@"fname"] urldecode];
        thread.tid = [rawThread objectForKey:@"tid"];
        thread.replyCount = [rawThread objectForKey:@"tid_sum"];
        thread.title = [[[rawThread objectForKey:@"pname"] urldecode] replaceHtmlEntities];

        [self.cellList addObject:[self createCellForThread:thread]];
        [self.dataList addObject:thread];
    }
}

#pragma mark - IBAction and unwind methods
- (IBAction)jumpToPoster:(id)sender forEvent:(UIEvent *)event {
    [self.indexController deselectCurrentRow];
    self.contentController.info = ((BUCThread *)[self.dataList objectAtIndex:[self getRowOfEvent:event]]).poster;
    [self.contentController performSegueWithIdentifier:@"segueToUser" sender:nil];
}

- (IBAction)jumpToForum:(id)sender forEvent:(UIEvent *)event {
    [self.indexController deselectCurrentRow];
    self.contentController.info = ((BUCThread *)[self.dataList objectAtIndex:[self getRowOfEvent:event]]).forum;
    [self.contentController performSegueWithIdentifier:@"segueToForum" sender:nil];
}

- (IBAction)jumpToThread:(id)sender forEvent:(UIEvent *)event {
    [self.indexController deselectCurrentRow];
    self.contentController.info = [self.dataList objectAtIndex:[self getRowOfEvent:event]];
    [self.contentController performSegueWithIdentifier:@"segueToThread" sender:nil];
}

- (IBAction)unwindToFront:(UIStoryboardSegue *)segue
{
    
}

#pragma mark - Table view data source and delegate methods
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

- (CGFloat)calculateHeightForText:(NSString *)text
{
    CGRect frame = [text boundingRectWithSize:CGSizeMake(250, FLT_MAX)
                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                   attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]}
                                      context:nil];
    
    CGFloat padding = 10;
    
    return MAX(60, frame.size.height + padding) + 32; // 32 = 5(space between the bottom buttons and the title) + 27(height of button)
}

- (BUCTableCell *)createCellForThread:(BUCThread *)thread
{
    static NSString *CellIdentifier = @"frontCell";
    
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
    
    UIButton *rightBottomBtn = [self cellButtonWithTitle:thread.forum.fname];
    
    size = [thread.forum.fname sizeWithAttributes:stringAttribute];
    rightBottomBtn.frame = CGRectMake(308 - size.width, cell.height - 27, size.width + 2, 27);
    [rightBottomBtn addTarget:self action:@selector(jumpToForum:forEvent:) forControlEvents:UIControlEventTouchUpInside];
    cell.rightBottomBtn = rightBottomBtn;
    [cell addSubview:rightBottomBtn];
    
    return cell;
}
@end





