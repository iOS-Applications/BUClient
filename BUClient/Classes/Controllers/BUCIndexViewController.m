//
//  BUCIndexViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/13/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCIndexViewController.h"
#import "BUCMainViewController.h"

@interface BUCIndexViewController ()
@property NSArray *list;
@end

@implementation BUCIndexViewController
#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _list = [NSArray arrayWithObjects:@"segueToFront", @"segueToForumList", nil];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"greyBackground.png"]];
    [tempImageView setFrame:self.tableView.frame];
    
    self.tableView.backgroundView = tempImageView;
    [self.tableView sendSubviewToBack:tempImageView];
}

#pragma mark - public methods
- (void)deselectCurrentRow
{
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:path animated:NO];
}

#pragma mark - Table view delegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *segueIdentifier = [self.list objectAtIndex:indexPath.row];
    [(BUCMainViewController *)self.parentViewController switchContentWith:segueIdentifier];
}

@end
