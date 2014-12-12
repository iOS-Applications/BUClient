#import "BUCBookmarkController.h"
#import "BUCPostDetailController.h"
#import "BUCModels.h"

@interface BUCBookmarkController ()

@property (nonatomic) NSMutableArray *list;
@property (nonatomic) NSString *path;
@property (nonatomic) BOOL listChanged;

@end

@implementation BUCBookmarkController
#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:@"/BUCBookmarkList.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
        self.list = [NSMutableArray arrayWithContentsOfFile:self.path];
    }

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (!editing && self.listChanged) {
        [self.list writeToFile:self.path atomically:YES];
        self.listChanged = NO;
    }
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.list.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    NSDictionary *post = [self.list objectAtIndex:indexPath.row];
    cell.textLabel.text = [post objectForKey:@"title"];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.list removeObjectAtIndex:indexPath.row];
        self.listChanged = YES;
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSDictionary *post = [self.list objectAtIndex:fromIndexPath.row];
    [self.list removeObjectAtIndex:fromIndexPath.row];
    [self.list insertObject:post atIndex:toIndexPath.row];
    self.listChanged = YES;
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSDictionary *item = [self.list objectAtIndex:indexPath.row];
    BUCPost *post = [[BUCPost alloc] init];
    post.tid = [item objectForKey:@"tid"];
    post.title = [[NSAttributedString alloc] initWithString:[item objectForKey:@"title"]];
    post.bookmarked = YES;
    post.bookmarkIndex = indexPath.row;
    BUCPostDetailController *detailController = (BUCPostDetailController *)segue.destinationViewController;
    detailController.post = post;
}


@end
