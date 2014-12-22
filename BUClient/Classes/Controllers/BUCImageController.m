#import "BUCImageController.h"
#import "BUCDataManager.h"

@interface BUCImageController () <UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) CGFloat nativeWidth;
@property (nonatomic) CGFloat nativeHeight;
@property (nonatomic) CGFloat screenWidth;
@property (nonatomic) CGFloat screenHeight;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *oneTap;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *twoTap;

@end

@implementation BUCImageController
- (void)setupGeometry {
    self.nativeWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    self.nativeHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
    if (self.nativeWidth > self.nativeHeight) {
        CGFloat save = self.nativeWidth;
        self.nativeWidth = self.nativeHeight;
        self.nativeHeight = save;
    }
    [self setUpGeometryDependingOnOrientation];
}


- (void)setUpGeometryDependingOnOrientation {
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(deviceOrientation)) {
        self.screenWidth = self.nativeHeight;
        self.screenHeight = self.nativeWidth;
    } else {
        self.screenWidth = self.nativeWidth;
        self.screenHeight = self.nativeHeight;
    }
}


- (IBAction)scrollViewDoubleTapped:(UITapGestureRecognizer*)recognizer {
    if (self.scrollView.zoomScale == 1.0f) {
        CGPoint pointInView = [recognizer locationInView:self.imageView];
        CGFloat newZoomScale = self.scrollView.zoomScale * 1.5f;
        newZoomScale = MIN(newZoomScale, self.scrollView.maximumZoomScale);
        CGSize scrollViewSize = self.scrollView.bounds.size;
        CGFloat w = scrollViewSize.width / newZoomScale;
        CGFloat h = scrollViewSize.height / newZoomScale;
        CGFloat x = pointInView.x - (w / 2.0f);
        CGFloat y = pointInView.y - (h / 2.0f);
        CGRect rectToZoomTo = CGRectMake(x, y, w, h);
        [self.scrollView zoomToRect:rectToZoomTo animated:YES];
    } else {
        [self.scrollView setZoomScale:1.0f animated:YES];
    }
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupGeometry];
    self.imageView.frame = CGRectMake(0.0f, 0.0f, self.screenWidth, self.screenHeight);

    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.screenWidth, self.screenHeight)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.backgroundColor = [UIColor blackColor];
    self.imageView.userInteractionEnabled = YES;
    [self.scrollView addSubview:self.imageView];
    self.scrollView.contentSize = self.imageView.frame.size;

    [self.oneTap requireGestureRecognizerToFail:self.twoTap];
    [[BUCDataManager sharedInstance] getImageWithUrl:self.attachment.url size:CGSizeZero onSuccess:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
            CGFloat scaledHeight = image.size.height * self.screenWidth / image.size.width;
            if (scaledHeight > self.screenHeight) {
                CGRect frame = self.imageView.frame;
                frame.size.height = scaledHeight;
                self.imageView.frame = frame;
            }
            self.scrollView.contentSize = self.imageView.frame.size;
        });
    }];
}


- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerScrollViewContents];
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self setUpGeometryDependingOnOrientation];
    UIImage *image = self.imageView.image;
    self.imageView.frame = CGRectMake(0.0f, 0.0f, self.screenWidth, self.screenHeight);

    CGFloat scaledHeight = image.size.height * self.screenWidth / image.size.width;
    if (scaledHeight > self.screenHeight) {
        self.imageView.frame = CGRectMake(0.0f, 0.0f, self.screenWidth, scaledHeight);
    }
    self.scrollView.contentSize = CGSizeMake(self.screenWidth, self.imageView.frame.size.height);
}

- (void)centerScrollViewContents {
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = ceilf((boundsSize.width - contentsFrame.size.width) / 2.0f);
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = ceilf((boundsSize.height - contentsFrame.size.height) / 2.0f);
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    
    self.imageView.frame = contentsFrame;
}


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}


- (IBAction)dismiss:(UITapGestureRecognizer *)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
