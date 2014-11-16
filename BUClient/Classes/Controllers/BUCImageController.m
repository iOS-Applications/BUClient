//
//  BUCImageController.m
//  BUClient
//
//  Created by Joe Jeong on 11/12/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCImageController.h"

@interface BUCImageController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation BUCImageController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//    
//    CGFloat imageWidth = self.image.size.width;
//    CGFloat imageHeight = self.image.size.height;
//    
//    CGFloat imageViewWidth = CGRectGetWidth(self.imageView.frame);
//    CGFloat imageViewHeight = CGRectGetHeight(self.imageView.frame);
//  
//    if (imageViewHeight < imageHeight) {
//        CGFloat temp = imageHeight * imageViewWidth / imageWidth;
//        if (temp > imageViewHeight) {
//            imageViewHeight = temp;
//        }
//    }
//    
//    self.imageView.image = self.image;
//    self.imageView.frame = CGRectMake(0, 0, imageViewWidth, imageViewHeight);
//    UIScrollView *context = (UIScrollView *)self.view;
//    context.contentSize = CGSizeMake(imageViewWidth, imageViewHeight);
//    self.imageView.frame = CGRectMake(0, 0, self.image.size.width, self.image.size.height);


}



- (IBAction)tapImage:(UITapGestureRecognizer *)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
