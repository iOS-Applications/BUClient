#import "BUCPostDetailController.h"
#import "BUCDataManager.h"
#import "BUCPost.h"
#import "BUCPostFragment.h"


@interface BUCPostDetailController () <UIScrollViewDelegate>


@property (nonatomic) NSArray *postList;


@end


@implementation BUCPostDetailController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIScrollView *context = (UIScrollView *)self.view;
    context.delegate = self;
    context.contentInset = UIEdgeInsetsZero;
    
}


- (void)viewDidAppear:(BOOL)animated {
    [self refresh:nil];
}


- (IBAction)refresh:(id)sender {
    [self displayLoading];
    [self loadList];
}


#pragma mark - private methods
- (void)loadList {
    BUCPostDetailController * __weak weakSelf = self;
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
//    UIView *listWrapper = self.LISTWRAPPER;
    
    [dataManager
     getPost:self.postID
     
     from:@"0"
     
     to:@"20"
     
     onSuccess:^(NSArray *list) {
         weakSelf.postList = list;
//         [listWrapper removeFromSuperview];
         [weakSelf buildList:list];
         [weakSelf hideLoading];
     }
     
     onError:^(NSError *error) {
         [weakSelf hideLoading];
         [weakSelf alertMessage:error.localizedDescription];
     }];
}


- (void)buildList:(NSArray *)list {

}


- (void)displayLoading {
    
}


- (void)hideLoading {
    
}


@end



















