//
//  BUCUserViewController.m
//  BUClient
//
//  Created by Joe Jeong on 2/10/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCUserViewController.h"
#import "BUCPost.h"

@interface BUCUserViewController ()
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *credit;
@property (weak, nonatomic) IBOutlet UILabel *threadCount;
@property (weak, nonatomic) IBOutlet UILabel *postCount;
@property (weak, nonatomic) IBOutlet UILabel *registerDate;
@property (weak, nonatomic) IBOutlet UILabel *lastLoginDate;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;

@property BOOL loadImage;
@end

@implementation BUCUserViewController
#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self.postDic setObject:@"profile" forKey:@"url"];
        [self.postDataDic setObject:@"profile" forKey:@"action"];
        [self.postDataDic setObject:@"" forKey:@"uid"];
        _loadImage = [self.user.loadImage isEqualToString:@"yes"] ? YES : NO;
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!self.loadImage) {
        self.avatar.hidden = YES;
    }
}

- (void)dealloc
{
    [self.responseDataArray removeObserver:self fromObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 20)] forKeyPath:@"avatar" context:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDictionary *infoDic = self.contentController.infoDic;
    NSString *username = [infoDic objectForKey:@"username"];
    [self.postDataDic setObject:username forKey:@"queryusername"];
    self.navigationItem.title = username;
    
    self.responseDataArray = self.engine.responseDataArray;
    [self.responseDataArray addObserver:self toObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 20)] forKeyPath:@"avatar" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self loadData:self.postDic];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"responseDic"]) {
        if (self.responseDic) {
            NSDictionary *userDic = [self.responseDic objectForKey:@"memberinfo"];
            self.username.text = [[userDic objectForKey:@"username"] urldecode];
            self.credit.text = [userDic objectForKey:@"credit"];
            self.threadCount.text = [userDic objectForKey:@"threadnum"];
            self.postCount.text = [userDic objectForKey:@"postnum"];
            NSString *timestamp = [userDic objectForKey:@"lastvisit"];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[timestamp integerValue]];
            static NSDateFormatter *dateFormatter = nil;
            if (!dateFormatter) {
                dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
                NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                [dateFormatter setLocale:locale];
            }
            self.lastLoginDate.text = [dateFormatter stringFromDate:date];
            
            timestamp = [userDic objectForKey:@"regdate"];
            date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[timestamp integerValue]];
            self.registerDate.text = [dateFormatter stringFromDate:date];
            
            if (self.loadImage) {
                NSString *avatar = [[userDic objectForKey:@"avatar"] urldecode];
                
                // test code start
                avatar = @"http://0.0.0.0:8080/static/avatar.png";
                // test code end
                
                [self loadImage:avatar atIndex:0];
            }
            
            [self endLoading];
        }
    } else {
        NSData *data = ((BUCPost *)[self.responseDataArray objectAtIndex:0]).avatar;
        self.avatar.image = [UIImage imageWithData:data];
    }
}
- (IBAction)testshit:(id)sender {
    NSData *data = [[self.responseDataArray objectAtIndex:0] objectForKey:@"data"];
    self.avatar.image = [UIImage imageWithData:data];
}
@end
























