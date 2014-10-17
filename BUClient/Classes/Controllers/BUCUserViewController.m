//
//  BUCUserViewController.m
//  BUClient
//
//  Created by Joe Jeong on 2/10/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCUserViewController.h"

@interface BUCUserViewController ()

@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *credit;
@property (weak, nonatomic) IBOutlet UILabel *threadCount;
@property (weak, nonatomic) IBOutlet UILabel *postCount;
@property (weak, nonatomic) IBOutlet UILabel *registerDate;
@property (weak, nonatomic) IBOutlet UILabel *lastLoginDate;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;

@property (nonatomic) BUCPoster *member;

@property (nonatomic) BUCTask *avatarTask;

@property (nonatomic) BOOL loadImage;

@end

@implementation BUCUserViewController
#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.task.json = self.user.json;
        [self.task.json setObject:@"profile" forKey:@"action"];
        self.task.url = @"profile";
        _loadImage = [self.user.loadImage isEqualToString:@"yes"] ? YES : NO;
    }
    
    return self;
}

- (void)dealloc
{
    if (self.loadImage) {
        if (!self.avatarTask.done) [self.avatarTask.task cancel];
        [self.avatarTask removeObserver:self forKeyPath:@"data" context:NULL];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.member = (BUCPoster *)self.contentController.info;
    [self.task.json setObject:self.member.username forKey:@"queryusername"];
    self.navigationItem.title = self.member.username;
    
    if (self.loadImage) {
        self.avatarTask = [[BUCTask alloc] init];
        self.avatarTask.done = YES;
        [self.avatarTask addObserver:self forKeyPath:@"data" options:NSKeyValueObservingOptionNew context:NULL];
    }
    
    [self startAllTasks];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    BUCTask *task = (BUCTask *)object;
    
    if ([keyPath isEqualToString:@"jsonData"]) {
        NSDictionary *userDic = [task.jsonData objectForKey:@"memberinfo"];
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
            self.avatarTask.url = [[userDic objectForKey:@"avatar"] urldecode];
            
            // test code start
//            self.avatarTask.url = @"http://0.0.0.0:8080/static/funny.png";
            // test code end
            
            [self loadDataOfTask:self.avatarTask];
        }
        
        [self endLoading];
    } else {
        self.avatar.image = [UIImage imageWithData:task.data];
    }
}
@end
























