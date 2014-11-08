#import "BUCBaseController.h"


@interface BUCBaseController ()


@property (strong, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;


@end


@implementation BUCBaseController


#pragma mark - overrided methods
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSBundle mainBundle] loadNibNamed:@"BUCLoadingView" owner:self options:nil];
    // set up loading view
    self.loadingView.frame = CGRectMake(0, 0, 140.0f, 140.0f);
    self.loadingView.center = self.view.center;
    self.loadingView.layer.cornerRadius = 10.0f;    
    [self.view addSubview:self.loadingView];
}


#pragma mark - public methods
- (void)displayLoading {
    [self.activityIndicator startAnimating];
    [self.view bringSubviewToFront:self.loadingView];
    self.loadingView.hidden = NO;
}


- (void)hideLoading {
    [self.activityIndicator stopAnimating];
    self.loadingView.hidden = YES;
    [self.view sendSubviewToBack:self.loadingView];
}


- (void)alertMessage:(NSString *)message {
    [[[UIAlertView alloc]
      initWithTitle:nil
      message:message
      delegate:self
      cancelButtonTitle:@"OK"
      otherButtonTitles:nil] show];
}


@end
