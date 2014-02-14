//
//  BUCForumListViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCForumListViewController.h"

static NSString *nameKey = @"name";
static NSString *forumListKey = @"forumList";
static NSString *mainKey = @"main";
static NSString *subKey = @"sub";
static NSString *fidKey = @"fid";
static NSString *painInMyAss = @"站庆专版";

@implementation BUCForumListViewController

#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self.requestDic setObject:@"forum" forKey:@"url"];
        [self.jsonDic setObject:@"forum" forKey:@"action"];
        self.rawListKey = @"forumslist";
        self.unwindSegueIdentifier = @"unwindToForumList";
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadData:self.requestDic];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.rawDataDic) {
        // temporary mother fucking forum list solution
        NSMutableArray *tempDataList = [[NSMutableArray alloc]
                                        initWithObjects:[NSNull null],[NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
        NSMutableArray *tempCellList = [NSMutableArray arrayWithArray:tempDataList];
        
        NSDictionary *indexDic = @{ @"2": @0, @"129": @1, @"166": @2, @"16": @3, @"13": @4 };
        NSInteger index;
        
        NSDictionary *rawSection = nil;
        NSDictionary *rawDic = [self.rawDataDic objectForKey:self.rawListKey];
        
        for (NSString *key in rawDic) {
            rawSection = [rawDic objectForKey:key];
            if (![key length] || ([rawSection count] == 1)) continue;
            
            BUCSection *section = [[BUCSection alloc] init];
            NSMutableArray *cellSection = [[NSMutableArray alloc] init];
            
            section.forumList = [[NSMutableArray alloc] init];
            section.sname = [[[rawSection objectForKey:mainKey] objectForKey:nameKey] urldecode];
            BUCForum *forum = nil;
            NSString *fname = nil;
            
            for (NSString *key in rawSection) {
                if ([key isEqualToString:mainKey]) continue;
                
                NSDictionary *rawForumDic = [rawSection objectForKey:key];
                for (NSDictionary *rawForum in [rawForumDic objectForKey:mainKey]) {
                    forum = [[BUCForum alloc] init];
                    forum.fid = [rawForum objectForKey:fidKey];
                    forum.fname = [[rawForum objectForKey:nameKey] urldecode];
                    forum.type = mainKey;
                    [cellSection addObject:[self createCellForForum:forum]];
                    [section.forumList addObject:forum];
                }
                
                for (NSDictionary *rawForum in [rawForumDic objectForKey:subKey]) {
                    forum = [[BUCForum alloc] init];
                    forum.fid = [rawForum objectForKey:fidKey];
                    fname = [[rawForum objectForKey:nameKey] urldecode];
                    forum.fname = [fname rangeOfString:painInMyAss].length ? painInMyAss : fname;
                    forum.type = subKey;
                    [cellSection addObject:[self createCellForForum:forum]];
                    [section.forumList addObject:forum];
                }
            }
            
            index = [[indexDic objectForKey:key] integerValue];
            [tempDataList setObject:section atIndexedSubscript:index];
            [tempCellList setObject:cellSection atIndexedSubscript:index];
        }
        
        [tempCellList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (obj == [NSNull null]) return;
            
            [self.cellList addObject:obj];
        }];
        
        [tempDataList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (obj == [NSNull null]) return;
            
            [self.dataList addObject:obj];
        }];
        
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
    return [self.cellList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.cellList objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self.cellList objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return ((BUCSection *)[self.dataList objectAtIndex:section]).sname;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.indexController deselectCurrentRow];
    
    BUCForum *forum = [((BUCSection *)[self.dataList objectAtIndex:indexPath.section]).forumList objectAtIndex:indexPath.row];
    self.contentController.info = forum;
    [self.contentController performSegueWithIdentifier:@"segueToForum" sender:nil];
}

#pragma mark - private methods
- (UITableViewCell *)createCellForForum:(BUCForum *)forum
{
    static NSString *CellIdentifier = @"forumListCell";
    static NSString *subForumFormat = @"> %@";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.textLabel.text = [forum.type isEqualToString:subKey] ? [NSString stringWithFormat:subForumFormat, forum.fname] : forum.fname;
    
    return cell;
}
@end







