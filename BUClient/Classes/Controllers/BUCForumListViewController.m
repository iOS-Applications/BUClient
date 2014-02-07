//
//  BUCForumListViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCForumListViewController.h"

@interface BUCForumListViewController ()

@end

@implementation BUCForumListViewController
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self.postDic setObject:@"forum" forKey:@"url"];
        [self.postDataDic setObject:@"forum" forKey:@"action"];
        self.listKey = @"forumslist";
    }
    
    return self;
}

- (IBAction)unwindToForumList:(UIStoryboardSegue *)segue
{
    
}

#pragma mark - Table view data source and delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.list count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.list objectAtIndex:section] objectForKey:@"forumList"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"forumListCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSString *name = [[[[self.list objectAtIndex:indexPath.section] objectForKey:@"forumList"] objectAtIndex:indexPath.row] objectForKey:@"name"];
    NSRange r = [name rangeOfString:@"站庆专版"];
    if (r.length) {
        name = @"> 站庆专版";
    }
    cell.textLabel.text = name;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[self.list objectAtIndex:section] objectForKey:@"info"] objectForKey:@"name"];
}
@end
