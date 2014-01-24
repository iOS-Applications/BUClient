//
//  BUCFrontPageViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCFrontPageViewController.h"
#import "BUCFrontPageTableCell.h"

@interface BUCFrontPageViewController ()
{
    NSString *text;
}

@end

@implementation BUCFrontPageViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    text = @"从香港直飞北京，想带一部iphone5s，怎么过安检？会不会收税？需要拆封么？托运还是随身带";
    //text = @"世界，你好";
    //text = @"grails geb -baseUrl option does not work for remote services";
    text = @"hello, world";

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier;
    if (indexPath.row & 1) {
        CellIdentifier = @"odd";
    } else {
        CellIdentifier = @"even";
    }

    BUCFrontPageTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [cell.author setTitle:@"jox0" forState:UIControlStateNormal];
    [cell.subforum setTitle:@"iOS Programming" forState:UIControlStateNormal];
    [cell.replyCount setTitle:@"1000" forState:UIControlStateNormal];
    
    NSDictionary *stringAttribute = @{NSFontAttributeName:[UIFont systemFontOfSize:18.0]};
    CGRect frame = [text boundingRectWithSize:CGSizeMake(230, FLT_MAX)
                                       options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                    attributes:stringAttribute
                                       context:nil];
    
    CGFloat padding = 10.0;         // padding of text view is not documented, compensation height need to be set here
    
    if (frame.size.height < 25) {   // padding of text is different when there is only one line of text
        padding = 6.0;
    }
    
    frame.size.height = frame.size.height + padding;
    frame.size.width = 230.0;       // width of text view need to be set when there is only one line of text
    CGSize size = frame.size;
    cell.title.frame = frame;
    cell.title.text = text;
    cell.title.font = [UIFont systemFontOfSize:18.0];
//    [cell.title setTextColor:[UIColor colorWithRed:0.0/255.0 green:100.0/255 blue:255.0/255.0 alpha:1.0]];
    
    stringAttribute = @{NSFontAttributeName: [UIFont systemFontOfSize:15.0]};
    CGFloat linkY = MAX(60, size.height);
    
    size = [cell.author.titleLabel.text sizeWithAttributes:stringAttribute];
    cell.author.frame = CGRectMake(10, linkY, size.width + 2.0, 27.0);      // 2 is the width to compensate padding of button element

    size = [cell.subforum.titleLabel.text sizeWithAttributes:stringAttribute];
    cell.subforum.frame = CGRectMake(308 - size.width, linkY, size.width + 2.0, 27.0);
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect frame = [text boundingRectWithSize:CGSizeMake(230, FLT_MAX)
                                       options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                    attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18.0]}
                                       context:nil];
    
    CGFloat padding = 10.0;
    
    if (frame.size.height < 25.0) {
        padding = 3.0;
    }

    return MAX(60, frame.size.height) + padding + 32.0; // 32 = 5(bottom space) + 27(height of button)
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
