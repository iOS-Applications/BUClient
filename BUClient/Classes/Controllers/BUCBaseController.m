#import "BUCBaseController.h"


@interface BUCBaseController ()


@property (strong, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic) UIAlertView *alertView;
@property (nonatomic) UIAlertController *alert;

@end


@implementation BUCBaseController


#pragma mark - overrided methods
- (void)viewDidLoad {
    [super viewDidLoad];

    // set up loading view
    [self.nibBundle loadNibNamed:@"BUCLoadingView" owner:self options:nil];
    
    self.loadingView.frame = CGRectMake(0, 0, 140.0f, 140.0f);
    self.loadingView.layer.cornerRadius = 10.0f;
    self.loadingView.layer.masksToBounds = YES;
    [self.view addSubview:self.loadingView];
    
    if ([UIAlertController class]) {
        self.alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
        [self.alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}]];
    } else {
        self.alertView = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    }
}


#pragma mark - public methods
- (void)displayLoading {
    [self.activityIndicator startAnimating];
    CGRect frame = self.view.bounds;
    CGFloat x = CGRectGetMidX([UIScreen mainScreen].bounds);
    CGFloat y = frame.origin.y + CGRectGetMidY([UIScreen mainScreen].bounds) - 64.0f;
    self.loadingView.center = CGPointMake(x, y);
    self.loadingView.hidden = NO;
    [self.view bringSubviewToFront:self.loadingView];
}


- (void)hideLoading {
    [self.activityIndicator stopAnimating];
    self.loadingView.hidden = YES;
    [self.view sendSubviewToBack:self.loadingView];
}


- (void)alertMessage:(NSString *)message {
    if (self.alert) {
        self.alert.message = message;
        [self presentViewController:self.alert animated:YES completion:nil];
    } else if (self.alertView) {
        self.alertView.message = message;
        [self.alertView show];
    }
}


@end
