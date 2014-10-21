//
//  BUCDataManager.m
//  BUClient
//
//  Created by Joe Jeong on 10/20/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCDataManager.h"
#import "BUCNetworkEngine.h"
#import "BUCAuthManager.h"
#import "NSObject+BUCTools.h"

#import "BUCPost.h"

@interface BUCDataManager ()

@end

@implementation BUCDataManager
+ (BUCDataManager *)sharedInstance
{
    static BUCDataManager *sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
                      sharedInstance = [[self alloc] init];
                  });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        
    }
    
    return self;
}

- (void)getFrontListOnSuccess:(ArrayBlock)arrayBlock onFail:(FailBlock)failBlock
{
    BUCDataManager * __weak weakSelf = self;
    
    BUCAuthManager *authManager = [BUCAuthManager sharedInstance];
    if (!authManager.session) {
        [authManager updateSessionOnSuccess:^(void) {
            [weakSelf getFrontListOnSuccess:arrayBlock onFail:failBlock];
        }
                                     onFail:^(NSError *error) {
                                         failBlock(error);
                                     }];
        return;
    }
    
    NSMutableDictionary *queryJSON = [[NSMutableDictionary alloc] init];
    [queryJSON setObject:authManager.curUser forKey:@"username"];
    [queryJSON setObject:authManager.session forKey:@"session"];
    
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    NSString *url = [NSString stringWithFormat:engine.baseUrl, @"home"];
    NSError *error = nil;
    NSURLRequest *req = [self requestWithUrl:url json:queryJSON error:&error];
    if (!req) {
        failBlock(error);
        return;
    }
    
    [engine processRequest:req
                  onResult:^(NSDictionary *json) {
                      NSString *result = [json objectForKey:@"result"];
                      if ([result isEqualToString:@"fail"]) {
                          [authManager updateSessionOnSuccess:^(void) {
                              [weakSelf getFrontListOnSuccess:arrayBlock onFail:failBlock];
                          }
                                                       onFail:^(NSError *error) {
                                                           failBlock(error);
                                                       }];
                      }
                      
                      NSMutableArray *list = [[NSMutableArray alloc] init];
                      NSArray *rawArray = [json objectForKey:@"newlist"];
                      BUCPost *post = nil;
                      for (NSDictionary *rawDic in rawArray) {
                          post = [[BUCPost alloc] init];
                          
                          post.pid = [rawDic objectForKey:@"tid"];
                          post.fid = [rawDic objectForKey:@"fid"];
                          post.fname = [[rawDic objectForKey:@"fname"] urldecode];
                          
                          post.user = [[rawDic objectForKey:@"author"] urldecode];
                          
                          post.title = [[[rawDic objectForKey:@"pname"] urldecode] replaceHtmlEntities];
                          
                          post.childCount = [rawDic objectForKey:@"tid_sum"];
                          
                          [list addObject:post];
                      }
                      
                      arrayBlock(list);
                  }
                   onError:^(NSError *error) {
                       failBlock(error);
                   }];
     
    
}
@end























