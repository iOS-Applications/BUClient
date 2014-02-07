//
//  BUCFrontPageViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCFrontPageViewController.h"
#import "BUCTableCell.h"
#import "NSString+NSString_Extended.h"
#import "BUCRoundButtonView.h"

@interface BUCFrontPageViewController ()


@end

@implementation BUCFrontPageViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self.postDic setObject:@"home" forKey:@"url"];
        self.listKey = @"newlist";
    }
    
    return self;
}

#pragma mark - unwind methods
- (IBAction)unwindToFront:(UIStoryboardSegue *)segue
{
    
}

- (IBAction)shit:(id)sender forEvent:(UIEvent *)event {
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self.tableView];
    NSLog(@"%f, %f", p.x, p.y);
    NSLog(@"%i", [self.tableView indexPathForRowAtPoint:p].row);
}


#pragma mark - Table view data source and delegate methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"frontCell";

    BUCTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    CGFloat cellHeight = cell.frame.size.height;
    NSDictionary *post = [self.list objectAtIndex:indexPath.row];
    
    [cell.replyCount setTitle:[post objectForKey:@"tid_sum"] forState:UIControlStateNormal];
    
    CGRect frame = CGRectMake(0, 0, 230, cellHeight - 32);
    cell.title.frame = frame;
    cell.title.text = [[[post objectForKey:@"pname"] urldecode] replaceHtmlEntities];
    cell.title.font = [UIFont systemFontOfSize:18];
    

    NSDictionary *stringAttribute = @{NSFontAttributeName:[UIFont systemFontOfSize:15]};
    
    NSString *author = [[post objectForKey:@"author"] urldecode];
    UIButton *authorBtn = [self cellButtonWithTitle:author];

    CGSize size = [author sizeWithAttributes:stringAttribute];
    authorBtn.frame = CGRectMake(10, cellHeight - 27, size.width + 2, 27);      // 2 is the width to compensate padding of button element
    cell.authorBtn = authorBtn;
    [cell addSubview:authorBtn];

    NSString *subforum = [[post objectForKey:@"fname"] urldecode];
    UIButton *subforumBtn = [self cellButtonWithTitle:subforum];
    
    size = [subforum sizeWithAttributes:stringAttribute];
    subforumBtn.frame = CGRectMake(308 - size.width, cellHeight - 27, size.width + 2, 27);
    cell.subforumBtn = subforumBtn;
    [cell addSubview:subforumBtn];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *post = [self.list objectAtIndex:indexPath.row];
    NSString *text = [[post objectForKey:@"pname"] urldecode];
    CGRect frame = [text boundingRectWithSize:CGSizeMake(230, FLT_MAX)
                                       options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                    attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]}
                                       context:nil];
    
    CGFloat padding = 10;
    
    if (frame.size.height < 25) {
        padding = 3;
    }

    return MAX(60, frame.size.height + padding) + 32; // 32 = 5(space between the bottom buttons and the title) + 27(height of button)
}

#pragma mark - private methods
- (UIButton *)cellButtonWithTitle:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    
    return button;
}

#pragma mark - EventInterceptWindow delegate methods
- (void)interceptEvent:(UIEvent *)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self.tableView];
    NSIndexPath *path = [self.tableView indexPathForRowAtPoint:p];
    NSLog(@"%f, %f", p.x, p.y);
    NSLog(@"%i", path.row);
}
@end
