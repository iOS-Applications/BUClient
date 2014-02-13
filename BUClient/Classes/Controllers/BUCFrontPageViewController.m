//
//  BUCFrontPageViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCFrontPageViewController.h"
#import "BUCTableCell.h"

@implementation BUCFrontPageViewController
#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self.postDic setObject:@"home" forKey:@"url"];
        self.listKey = @"newlist";
        
        self.unwindSegueIdentifier = @"unwindToFront";
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadData:self.postDic];
}

- (void)urldecodeData
{
    for (NSMutableDictionary *item in self.list) {
        NSString *string = [[item objectForKey:@"author"] urldecode];
        [item setObject:string forKey:@"author"];
        string = [[item objectForKey:@"pname"] urldecode];
        [item setObject:string forKey:@"pname"];
        string = [[item objectForKey:@"fname"] urldecode];
        [item setObject:string forKey:@"fname"];
    }
}

#pragma mark - IBAction and unwind methods
- (IBAction)jumpToAuthor:(id)sender forEvent:(UIEvent *)event {
    [self.indexController deselectCurrentRow];
    
    NSInteger row = [self getRowOfEvent:event];
    NSDictionary *thread = [self.list objectAtIndex:row];
    NSString *username = [thread objectForKey:@"author"];
    self.contentController.infoDic = @{ @"username": username };
    [self.contentController performSegueWithIdentifier:@"segueToUser" sender:nil];
}

- (IBAction)jumpToForum:(id)sender forEvent:(UIEvent *)event {
    [self.indexController deselectCurrentRow];
    
    NSInteger row = [self getRowOfEvent:event];
    NSDictionary *thread = [self.list objectAtIndex:row];
    NSString *fid = [thread objectForKey:@"fid"];
    NSString *fname = [thread objectForKey:@"fname"];
    self.contentController.infoDic = @{ @"fid": fid, @"fname":fname };
    [self.contentController performSegueWithIdentifier:@"segueToForum" sender:nil];
}

- (IBAction)jumpToPost:(id)sender forEvent:(UIEvent *)event {
    [self.indexController deselectCurrentRow];
    
    NSInteger row = [self getRowOfEvent:event];
    NSDictionary *thread = [self.list objectAtIndex:row];
    NSString *fid = [thread objectForKey:@"fid"];
    NSString *fname = [thread objectForKey:@"fname"];
    NSString *tid = [thread objectForKey:@"tid"];
    NSString *subject = [thread objectForKey:@"pname"];
    
    self.contentController.infoDic = @{ @"fid": fid, @"fname": fname, @"tid": tid, @"subject": subject };
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
    return [self.list count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"frontCell";

    BUCTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    CGFloat cellHeight = cell.frame.size.height;
    NSDictionary *post = [self.list objectAtIndex:indexPath.row];
    
    [cell.replyCount setTitle:[post objectForKey:@"tid_sum"] forState:UIControlStateNormal];
    
    CGRect frame = CGRectMake(0, 0, 250, cellHeight - 32);
    cell.title.frame = frame;
    cell.title.text = [[post objectForKey:@"pname"] replaceHtmlEntities];
    cell.title.font = [UIFont systemFontOfSize:18];
    

    NSDictionary *stringAttribute = @{NSFontAttributeName:[UIFont systemFontOfSize:15]};
    
    NSString *author = [post objectForKey:@"author"];
    UIButton *leftBottomBtn = [self cellButtonWithTitle:author];

    CGSize size = [author sizeWithAttributes:stringAttribute];
    leftBottomBtn.frame = CGRectMake(10, cellHeight - 27, size.width + 2, 27); // 2 is the width to compensate padding of button element
    [leftBottomBtn addTarget:self action:@selector(jumpToAuthor:forEvent:) forControlEvents:UIControlEventTouchUpInside];
    cell.leftBottomBtn = leftBottomBtn;
    [cell addSubview:leftBottomBtn];

    NSString *subforum = [post objectForKey:@"fname"];
    UIButton *rightBottomBtn = [self cellButtonWithTitle:subforum];
    
    size = [subforum sizeWithAttributes:stringAttribute];
    rightBottomBtn.frame = CGRectMake(308 - size.width, cellHeight - 27, size.width + 2, 27);
    [rightBottomBtn addTarget:self action:@selector(jumpToForum:forEvent:) forControlEvents:UIControlEventTouchUpInside];
    cell.rightBottomBtn = rightBottomBtn;
    [cell addSubview:rightBottomBtn];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *post = [self.list objectAtIndex:indexPath.row];
    NSString *text = [post objectForKey:@"pname"];
    CGRect frame = [text boundingRectWithSize:CGSizeMake(250, FLT_MAX)
                                       options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                    attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]}
                                       context:nil];
    
    CGFloat padding = 10;
    
    if (frame.size.height < 25) {
        padding = 3;
    }

    return MAX(60, frame.size.height + padding) + 32; // 32 = 5(space between the bottom buttons and the title) + 27(height of button)
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.indexController deselectCurrentRow];
    
    NSInteger row = indexPath.row;
    NSDictionary *thread = [self.list objectAtIndex:row];
    NSString *fid = [thread objectForKey:@"fid"];
    NSString *fname = [thread objectForKey:@"fname"];
    NSString *tid = [thread objectForKey:@"tid"];
    NSString *subject = [thread objectForKey:@"pname"];
    
    self.contentController.infoDic = @{ @"fid": fid, @"fname": fname, @"tid": tid, @"subject": subject };
    [self.contentController performSegueWithIdentifier:@"segueToThread" sender:nil];
}

#pragma mark - private methods
- (UIButton *)cellButtonWithTitle:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:15];
//    button.titleLabel.font = [UIFont systemFontOfSize:15];
    
    return button;
}

- (NSInteger)getRowOfEvent:(UIEvent *)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self.tableView];
    return [self.tableView indexPathForRowAtPoint:p].row;
}
@end





