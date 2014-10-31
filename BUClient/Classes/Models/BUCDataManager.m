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

#import "TFHpple.h"

@interface BUCDataManager ()

@end

@implementation BUCDataManager
#pragma mark - global access
+ (BUCDataManager *)sharedInstance
{
    static BUCDataManager *sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark - public methods
- (void)getFrontListOnSuccess:(ArrayBlock)arrayBlock onError:(ErrorBlock)errorBlock
{
    BUCDataManager * __weak weakSelf = self;
    BUCAuthManager *authManager = [BUCAuthManager sharedInstance];
    
    NSString *frontURL = @"home";
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:authManager.curUser forKey:@"username"];
    
    SuccessBlock successBlock = ^(NSDictionary *json)
    {
        NSMutableArray *list = [[NSMutableArray alloc] init];
        NSArray *rawArray = [json objectForKey:@"newlist"];
        BUCPost *post = nil;
        NSString *when = nil;
        NSString *who = nil;
        
        NSDictionary *captionAttrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]};
        
        for (NSDictionary *rawDic in rawArray)
        {
            post = [[BUCPost alloc] init];
            
            post.pid = [rawDic objectForKey:@"tid"];
            post.fid = [rawDic objectForKey:@"fid"];
            post.fname = [[NSAttributedString alloc] initWithString:[weakSelf urldecode:[rawDic objectForKey:@"fname"]]
                                                         attributes:captionAttrs];
            
            post.user = [[NSAttributedString alloc] initWithString:[weakSelf urldecode:[rawDic objectForKey:@"author"]]
                                                        attributes:captionAttrs];
            
            post.title = [weakSelf attributedStringFromHTML:[weakSelf urldecode:[rawDic objectForKey:@"pname"]]];
            
            post.childCount = [rawDic objectForKey:@"tid_sum"];
            
            when = [weakSelf urldecode:[[rawDic objectForKey:@"lastreply"] objectForKey:@"when"]];
            who = [weakSelf urldecode:[[rawDic objectForKey:@"lastreply"] objectForKey:@"who"]];
            post.lastReply = [[BUCPost alloc] init];
            post.lastReply.user = [[NSAttributedString alloc] initWithString:who attributes:captionAttrs];
            post.lastReply.dateline = when;
            
            [list addObject:post];
        }
        
        if (arrayBlock)
        {
            arrayBlock(list);
        }
    };
    
    [self loadListFromURL:frontURL json:json onSuccess:successBlock onError:errorBlock];
}

- (void)getPost:(NSString *)postID from:(NSString *)from to:(NSString *)to onSuccess:(ArrayBlock)arrayBlock onError:(ErrorBlock)errorBlock
{
    BUCDataManager * __weak weakSelf = self;
    BUCAuthManager *authManager = [BUCAuthManager sharedInstance];
    
    NSString *postURL = @"post";
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:@"post" forKey:@"action"];
    [json setObject:authManager.curUser forKey:@"username"];
    [json setObject:postID forKey:@"tid"];
    [json setObject:from forKey:@"from"];
    [json setObject:to forKey:@"to"];
    
    SuccessBlock successBlock = ^(NSDictionary *json)
    {
        NSMutableArray *list = [[NSMutableArray alloc] init];
        NSArray *rawArray = [json objectForKey:@"postlist"];
        BUCPost *post = nil;
        
        NSDictionary *captionAttrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]};
        
        for (NSDictionary *rawDic in rawArray)
        {
            post = [[BUCPost alloc] init];
            
            post.pid = [rawDic objectForKey:@"pid"];
            post.fid = [rawDic objectForKey:@"fid"];
            
            post.user = [[NSAttributedString alloc] initWithString:[weakSelf urldecode:[rawDic objectForKey:@"author"]]
                                                        attributes:captionAttrs];
            post.uid = [rawDic objectForKey:@"authorid"];
            post.title = [weakSelf attributedStringFromHTML:[weakSelf urldecode:[rawDic objectForKey:@"subject"]]];
            post.content = [weakSelf nodeTreeFromHTML:[weakSelf urldecode:[rawDic objectForKey:@"message"]]];
            post.dateline = [rawDic objectForKey:@"dateline"];
            
            [list addObject:post];
        }
        
        if (arrayBlock)
        {
            arrayBlock(list);
        }
    };
    
    [self loadListFromURL:postURL json:json onSuccess:successBlock onError:errorBlock];
}

#pragma mark - private methods
- (void)loadListFromURL:(NSString *)url json:(NSMutableDictionary *)json onSuccess:(SuccessBlock)successBlock onError:(ErrorBlock)errorBlock
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
             [weakSelf loadListFromURL:url json:json onSuccess:successBlock onError:errorBlock];
         }
         
         onFail:
         ^(NSError *error)
         {
             if (errorBlock)
             {
                 errorBlock(error);
             }
         }];
        
        return;
    }
    
    [json setObject:authManager.session forKey:@"session"];
    
    [engine
     fetchDataFromURL:url
     
     json:json
     
     onResult:
     ^(NSDictionary *resultJSON)
     {
         NSString *result = [resultJSON objectForKey:@"result"];
         if ([result isEqualToString:@"fail"])
         {
             [authManager
              updateSessionOnSuccess:
              ^(void)
              {
                  [weakSelf loadListFromURL:url json:json onSuccess:successBlock onError:errorBlock];
              }
              
              onFail:
              ^(NSError *error)
              {
                  if (errorBlock)
                  {
                      errorBlock(error);
                  }
              }];
         }
         
         if (successBlock)
         {
             successBlock(resultJSON);
         }
     }
     
     onError:errorBlock];
}

- (NSArray *)nodeTreeFromHTML:(NSString *)html
{
//    NSMutableArray *tree = [[NSMutableArray alloc] init];
    
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    NSString *query = @"//body";
    NSArray *nodes = [[[parser searchWithXPathQuery:query] firstObject] children];
    
    return nodes;
}

- (NSAttributedString *)attributedStringFromHTML:(NSString *)html
{
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] init];
    NSDictionary *textAttrs = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
    NSDictionary *colorAttrs = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                    NSForegroundColorAttributeName: [UIColor redColor]};
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    NSString *query = @"//body";
    NSArray *nodes = [[[parser searchWithXPathQuery:query] firstObject] children];
    
    NSDictionary *attrs = nil;
    NSString *content = nil;
    for (TFHppleElement *node in nodes)
    {
        if ([node hasChildren])
        {
            content = node.firstChild.content;
            if ([node.tagName isEqualToString:@"font"])
            {
                attrs = colorAttrs;
            }
            else
            {
                attrs = textAttrs;
            }
        }
        else
        {
            content = node.content;
            attrs = textAttrs;
        }

        content = [self replaceHtmlEntities:content];
        [output appendAttributedString:[[NSAttributedString alloc] initWithString:content attributes:attrs]];

    }
    
    return output;
}

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























