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

#import "BUCPost.h"

@interface BUCDataManager ()

@end

@implementation BUCDataManager
+ (BUCDataManager *)sharedInstance
{
    static BUCDataManager *sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        
    }
    
    return self;
}

- (void)getFrontListOnSuccess:(ArrayBlock)arrayBlock onFail:(FailBlock)failBlock
{
    BUCDataManager * __weak weakSelf = self;
    BUCAuthManager *authManager = [BUCAuthManager sharedInstance];
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    
    if (!authManager.session)
    {
        [authManager
         updateSessionOnSuccess:
         ^(void)
         {
             [weakSelf getFrontListOnSuccess:arrayBlock onFail:failBlock];
         }
         
         onFail:
         ^(NSError *error)
         {
             if (failBlock)
             {
                 failBlock(error);
             }
         }];
        
        return;
    }
    
    NSMutableDictionary *queryJSON = [[NSMutableDictionary alloc] init];
    [queryJSON setObject:authManager.curUser forKey:@"username"];
    [queryJSON setObject:authManager.session forKey:@"session"];
    
    NSString *url = [NSString stringWithFormat:engine.baseUrl, @"home"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    req.HTTPMethod = @"POST";
    
    [engine
     processRequest:req
     json:queryJSON
     onResult:
     ^(NSDictionary *json)
     {
         NSString *result = [json objectForKey:@"result"];
         if ([result isEqualToString:@"fail"])
         {
             [authManager
              updateSessionOnSuccess:
              ^(void)
              {
                  [weakSelf getFrontListOnSuccess:arrayBlock onFail:failBlock];
              }
              
              onFail:
              ^(NSError *error)
              {
                  if (failBlock)
                  {
                      failBlock(error);
                  }
              }];
         }
         
         NSMutableArray *list = [[NSMutableArray alloc] init];
         NSArray *rawArray = [json objectForKey:@"newlist"];
         BUCPost *post = nil;
         for (NSDictionary *rawDic in rawArray)
         {
             post = [[BUCPost alloc] init];
             
             post.pid = [rawDic objectForKey:@"tid"];
             post.fid = [rawDic objectForKey:@"fid"];
             post.fname = [self urldecode:[rawDic objectForKey:@"fname"]];
             
             post.user = [self urldecode:[rawDic objectForKey:@"author"]];
             
             post.title = [[NSAttributedString alloc]
                           initWithData:[[self urldecode:[rawDic objectForKey:@"pname"]] dataUsingEncoding:NSUTF8StringEncoding]
                           options:@{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,
                                     NSCharacterEncodingDocumentAttribute:@(NSUTF8StringEncoding)}
                           documentAttributes:nil
                           error:nil];
             
             post.childCount = [rawDic objectForKey:@"tid_sum"];
             
             [list addObject:post];
         }
         
         if (arrayBlock)
         {
             arrayBlock(list);
         }
     }
     
     onError:
     ^(NSError *error)
     {
         if (failBlock)
         {
             failBlock(error);
         }
     }];
}

#pragma mark - private methods
- (NSString *)urldecode:(NSString *)string
{
    return [[string stringByReplacingOccurrencesOfString:@"+" withString:@" "]
            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)replaceHtmlEntities:(NSString *)string
{
    return [[[[string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"]
              stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""]
             stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"]
            stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
}
@end























