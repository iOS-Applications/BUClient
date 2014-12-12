#import "BUCForumListController.h"
#import "BUCPostListController.h"

@interface BUCForumListController ()
@property (nonatomic) NSArray *sectionList;

@end

@implementation BUCForumListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.sectionFooterHeight = 0.0f;
    
    NSString *path = [self.nibBundle pathForResource:@"data/BUCForumList" ofType:@"plist"];
    self.sectionList = [NSArray arrayWithContentsOfFile:path];
    [self.tableView reloadData];
}


#pragma mark - Table view data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *forumSction = [self.sectionList objectAtIndex:section];
    NSArray *forumList = [forumSction objectForKey:@"list"];
    return forumList.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *forumSction = [self.sectionList objectAtIndex:section];
    return [forumSction objectForKey:@"name"];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BUCForumListCell" forIndexPath:indexPath];
    NSDictionary *forumSction = [self.sectionList objectAtIndex:indexPath.section];
    NSArray *forumList = [forumSction objectForKey:@"list"];
    NSDictionary *forum = [forumList objectAtIndex:indexPath.row];
    NSString *name = [forum objectForKey:@"display"];
    if (!name) {
        name = [forum objectForKey:@"name"];
    }
    cell.textLabel.text = name;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *forumSction = [self.sectionList objectAtIndex:indexPath.section];
    NSArray *forumList = [forumSction objectForKey:@"list"];
    self.selected = [forumList objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:self.unwindIdentifier sender:nil];
}


#pragma mark - navigation
- (IBAction)cancel {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}


@end




