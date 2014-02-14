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

@property (nonatomic) BOOL loadImage;

@end

@implementation BUCUserViewController
#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self.requestDic setObject:@"profile" forKey:@"url"];
        [self.jsonDic setObject:@"profile" forKey:@"action"];
        [self.jsonDic setObject:@"" forKey:@"uid"];
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
    [self.avatarList removeObserver:self
                      fromObjectsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                                forKeyPath:@"loadEnded"
                                   context:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.member = (BUCPoster *)self.contentController.info;
    [self.jsonDic setObject:self.member.username forKey:@"queryusername"];
    self.navigationItem.title = self.member.username;
    
    self.avatarList = self.engine.responseDataArray;
    [self.avatarList addObserver:self
                     toObjectsAtIndexes:[NSIndexSet indexSetWithIndex:0]
                             forKeyPath:@"loadEnded"
                                options:NSKeyValueObservingOptionNew
                                context:NULL];
    
    [self loadData:self.requestDic];
    
//    NSString *path = [[NSBundle mainBundle] bundlePath];
//    NSURL *baseURL = [NSURL fileURLWithPath:path];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"rawDataDic"]) {
        if (self.rawDataDic) {
            NSDictionary *userDic = [self.rawDataDic objectForKey:@"memberinfo"];
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
                NSString *avatarUrl = [[userDic objectForKey:@"avatar"] urldecode];
                
                // test code start
                avatarUrl = @"http://0.0.0.0:8080/static/avatar.png";
                // test code end
                
                [self loadImage:avatarUrl atIndex:0];
            }
            
            [self endLoading];
        }
    } else {
        BUCAvatar *avatar = [self.avatarList objectAtIndex:0];
        if (!avatar.loadEnded) return;
        
        NSError *error = avatar.error;
        
        if (!error) {
            self.avatar.image = avatar.image;
        } else {
            // handle error
        }
    }
}
@end
























