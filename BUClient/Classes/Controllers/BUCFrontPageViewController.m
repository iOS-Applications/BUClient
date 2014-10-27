//
//  BUCFrontPageViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCFrontPageViewController.h"
#import "BUCDataManager.h"
#import "BUCContentViewController.h"
#import "BUCPost.h"
#import "BUCPostListItemView.h"

@interface BUCFrontPageViewController ()

@property (nonatomic, weak) BUCContentViewController *contentVC;

@end

@implementation BUCFrontPageViewController
#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {

    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.contentVC = (BUCContentViewController *)self.parentViewController.parentViewController;
    [self.contentVC displayLoading];
    
    BUCFrontPageViewController * __weak weakSelf = self;
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
    [dataManager
     getFrontListOnSuccess:
     ^(NSArray *list)
     {
         [weakSelf buildList:list];
         [weakSelf.contentVC hideLoading];
     }
     onFail:^(NSError *error)		
     {
                                    
     }];
}

#pragma mark - IBAction and unwind methods
- (IBAction)jumpToPoster:(id)sender forEvent:(UIEvent *)event {
    
}

- (IBAction)refresh:(id)sender
{
    [self.contentVC displayLoading];
    
    BUCFrontPageViewController * __weak weakSelf = self;
    BUCDataManager *dataManager = [BUCDataManager sharedInstance];
    [dataManager
     getFrontListOnSuccess:
     ^(NSArray *list)
     {
         [weakSelf.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
         [weakSelf buildList:list];
         [weakSelf.contentVC hideLoading];
     }
     onFail:^(NSError *error)
     {
         [weakSelf.contentVC hideLoading];
         [weakSelf.contentVC alertMessage:error.localizedDescription];
     }];
}

- (IBAction)jumpToForum:(id)sender forEvent:(UIEvent *)event {

}

- (IBAction)jumpToThread:(id)sender forEvent:(UIEvent *)event {

}

- (IBAction)unwindToFront:(UIStoryboardSegue *)segue
{
    
}

#pragma mark - private methods
- (void)buildList:(NSArray *)list
{
    // contants
    CGFloat XOFFSET = 5.0f;
    CGFloat YOFFSET = 5.0f;
    CGFloat separatorHeight = 0.6f;
    
    // configure background of context
    UIScrollView *view = (UIScrollView *)self.view;
    view.backgroundColor = [UIColor colorWithRed:246.0f/255.0f green:246.0f/255.0f blue:246.0f/255.0f alpha:1.0f];
    
    // geometry
    CGRect frame = CGRectInset(view.bounds, XOFFSET, 0);
    CGFloat containerWidth = frame.size.width;
    CGFloat contentWidth = containerWidth - 2 * XOFFSET;
    
    // temporary variables
    BUCPostListItemView *container = nil;
    UILabel *text = nil;
    UIButton *button = nil;
    UIView *sep = nil;
    
    CGFloat posContainerY = YOFFSET;
    CGFloat contentCursorX;
    CGFloat contentCursorY;
    
    NSDictionary *captionAttrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]};
    NSAttributedString *caption = [[NSAttributedString alloc] initWithString:@"发表于"
                                                                  attributes:captionAttrs];
    
    for (BUCPost *post in list) {
        // reset render position indicators
        contentCursorX = XOFFSET;
        contentCursorY = YOFFSET;
        
        // container
        container = [[BUCPostListItemView alloc] init];
        container.layer.borderWidth = 0.3f;
        container.layer.borderColor = [UIColor lightGrayColor].CGColor;
        container.backgroundColor = [UIColor whiteColor];
        container.layer.cornerRadius = 4.0f;
        //[container addTarget:self action:@selector(shit:) forControlEvents:UIControlEventTouchUpInside];
        
        // title
        text = [[UILabel alloc] initWithFrame:CGRectMake(contentCursorX, contentCursorY, contentWidth, 0.0f)];
        text.numberOfLines = 0;
        text.attributedText = post.title;
        [text sizeToFit];
        [container addSubview:text];
        contentCursorY = contentCursorY + text.frame.size.height + YOFFSET * 4;
        
        // username
        button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setAttributedTitle:post.user forState:UIControlStateNormal];
        button.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 1.0f, 0.0f, 1.0f);
        [button sizeToFit];
        button.frame = CGRectOffset(button.frame, contentCursorX, contentCursorY);
        [container addSubview:button];
        contentCursorX = contentCursorX + button.frame.size.width + XOFFSET;
        
        // caption
        text = [[UILabel alloc] initWithFrame:CGRectMake(contentCursorX, contentCursorY, 0.0f, 0.0f)];
        text.attributedText = caption;
        [text sizeToFit];
        [container addSubview:text];
        contentCursorX = contentCursorX + text.frame.size.width + XOFFSET;
        
        // forum name
        button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setAttributedTitle:post.fname forState:UIControlStateNormal];
        button.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 1.0f, 0.0f, 1.0f);
        [button sizeToFit];
        button.frame = CGRectOffset(button.frame, contentCursorX, contentCursorY);
        [container addSubview:button];
        contentCursorX = contentCursorX + button.frame.size.width + XOFFSET;
        
        // reply count
        text = [[UILabel alloc] initWithFrame:CGRectMake(contentCursorX, contentCursorY, 0.0f, 0.0f)];
        text.attributedText = [[NSAttributedString alloc]
                               initWithString:[NSString stringWithFormat:@"回复数 %@", post.childCount]
                               attributes:captionAttrs];
        [text sizeToFit];
        [container addSubview:text];
        
        contentCursorY = contentCursorY + button.frame.size.height + YOFFSET;
        
        // add a separator
        sep = [[UIView alloc] initWithFrame:CGRectMake(XOFFSET, contentCursorY, contentWidth, separatorHeight)];
        sep.backgroundColor = [UIColor lightGrayColor];
        [container addSubview:sep];
        contentCursorY = contentCursorY + separatorHeight + YOFFSET;
        
        // newest reply
        contentCursorX = XOFFSET;
        
        text = [[UILabel alloc] initWithFrame:CGRectMake(XOFFSET, contentCursorY, 0.0f, 0.0f)];
        text.attributedText = [[NSAttributedString alloc]
                               initWithString:[NSString stringWithFormat:@"最后回复：%@ by", post.lastReply.dateline]
                               attributes:captionAttrs];
        [text sizeToFit];
        [container addSubview:text];
        contentCursorX = contentCursorX + text.frame.size.width + XOFFSET;
        
        button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setAttributedTitle:post.lastReply.user forState:UIControlStateNormal];
        button.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 1.0f, 0.0f, 1.0f);
        [button sizeToFit];
        button.frame = CGRectOffset(button.frame, contentCursorX, contentCursorY);
        [container addSubview:button];
        contentCursorY = contentCursorY + text.frame.size.height + YOFFSET;
        
        container.frame = CGRectMake(XOFFSET, posContainerY, containerWidth, contentCursorY);
        posContainerY = posContainerY + contentCursorY + YOFFSET;
        [view addSubview:container];
    }
    
    view.contentSize = CGSizeMake(view.bounds.size.width, posContainerY);
}
@end




