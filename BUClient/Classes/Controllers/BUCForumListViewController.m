//
//  BUCForumListViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCForumListViewController.h"

@implementation BUCForumListViewController

#pragma mark - overrided methods
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadData:self.postDic];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.responseDic) {
        // temporary mother fucking forum list solution start
        NSMutableArray *tempList = [[NSMutableArray alloc] initWithObjects:@"2", @"129", @"166", @"16", @"13", nil];
        NSDictionary *item;
        NSDictionary *tempDic = [self.responseDic objectForKey:self.listKey];
        
        for (NSString *key in tempDic) {
            item = [tempDic objectForKey:key];
            if (![key length] || ([item count] == 1)) continue;
            
            switch ([key integerValue]) {
                case 2:
                    [tempList setObject:item atIndexedSubscript:0];
                    break;
                case 129:
                    [tempList setObject:item atIndexedSubscript:1];
                    break;
                case 166:
                    [tempList setObject:item atIndexedSubscript:2];
                    break;
                case 16:
                    [tempList setObject:item atIndexedSubscript:3];
                    break;
                case 13:
                    [tempList setObject:item atIndexedSubscript:4];
                    break;
                default:
                    break;
            }
        }
        
        NSMutableArray *sectionList = [[NSMutableArray alloc] init];
        NSDictionary *section;
        
        NSMutableDictionary *forumInfo;
        NSMutableArray *forumList;
        NSArray *subforumList;
        
        NSDictionary *stuff;
        NSMutableDictionary *forum;
        NSMutableDictionary *subforum;
        
        NSString *name;
        
        for (id item in tempList) {
            if ([item isKindOfClass:[NSString class]]) continue;
            
            forumList = [[NSMutableArray alloc] init];
            forumInfo = [[NSMutableDictionary alloc] initWithDictionary:[item objectForKey:@"main"]];
            name = [forumInfo objectForKey:@"name"];
            [forumInfo setObject:[name urldecode] forKey:@"name"];
            
            for (NSString *key in item) {
                if (![key isEqualToString:@"main"]) {
                    stuff = [item objectForKey:key];
                    forum = [NSMutableDictionary dictionaryWithDictionary:[(NSArray *)[stuff objectForKey:@"main"] lastObject]];
                    name = [forum objectForKey:@"name"];
                    [forum setObject:[name urldecode] forKey:@"name"];
                    [forumList addObject:forum];
                    
                    if ([stuff count] > 1) {
                        subforumList = [stuff objectForKey:@"sub"];
                        for (NSDictionary *element in subforumList) {
                            subforum = [NSMutableDictionary dictionaryWithDictionary:element];
                            [subforum setObject:[[element objectForKey:@"name"] urldecode] forKey:@"name"];
                            if ([[subforum objectForKey:@"fup"] isEqualToString:@"14"] &&
                                [[subforum objectForKey:@"name"] rangeOfString:@"站庆专版"].length) {
                                
                                [subforum setObject:@"站庆专版" forKey:@"name"];
                            }
                            [forumList addObject:subforum];
                        }
                    }
                }
            }
            
            section = [[NSDictionary alloc] initWithObjectsAndKeys:forumInfo, @"info", forumList, @"forumList", nil];
            [sectionList addObject:section];
        }
        
        self.list = (NSArray *)sectionList;
        
        [self endLoading];
        [self.tableView reloadData];
    }
}

#pragma mark - unwind method
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
    NSDictionary *forum = [[[self.list objectAtIndex:indexPath.section] objectForKey:@"forumList"] objectAtIndex:indexPath.row];
    NSString *name = [forum objectForKey:@"name"];
    
    if ([[forum objectForKey:@"type"] isEqualToString:@"sub"]) {
        name = [NSString stringWithFormat:@"> %@", name];
    }
    
    cell.textLabel.text = name;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[self.list objectAtIndex:section] objectForKey:@"info"] objectForKey:@"name"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.indexController deselectCurrentRow];
    
    NSDictionary *forumSection = [self.list objectAtIndex:indexPath.section];
    NSDictionary *forum = [[forumSection objectForKey:@"forumList"] objectAtIndex:indexPath.row];
    NSString *fid = [forum objectForKey:@"fid"];
    NSString *postCount = [forum objectForKey:@"threads"];
    NSString *fname = [forum objectForKey:@"name"];
    self.contentController.infoDic = @{ @"fid": fid, @"postCount":postCount, @"fname":fname };
    [self.contentController performSegueWithIdentifier:@"segueToForum" sender:nil];
}

@end







