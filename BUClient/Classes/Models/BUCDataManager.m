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
+ (BUCDataManager *)sharedInstance
{
    static BUCDataManager *sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (void)getFrontListOnSuccess:(ArrayBlock)arrayBlock onFail:(FailBlock)failBlock
{
    NSString *frontURL = @"home";
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
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    [json setObject:authManager.curUser forKey:@"username"];
    [json setObject:authManager.session forKey:@"session"];
    
    [engine
     fetchDataFromURL:frontURL
     
     json:json
     
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
         NSString *when = nil;
         NSString *who = nil;
         
         NSDictionary *captionAttrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]};
         
         for (NSDictionary *rawDic in rawArray)
         {
             post = [[BUCPost alloc] init];
             
             post.pid = [rawDic objectForKey:@"tid"];
             post.fid = [rawDic objectForKey:@"fid"];
             post.fname = [[NSAttributedString alloc] initWithString:[self urldecode:[rawDic objectForKey:@"fname"]]
                                                          attributes:captionAttrs];
             
             post.user = [[NSAttributedString alloc] initWithString:[self urldecode:[rawDic objectForKey:@"author"]]
                                                         attributes:captionAttrs];
             
             post.title = [self attributedStringFromHtml:[self urldecode:[rawDic objectForKey:@"pname"]]];
             
             post.childCount = [rawDic objectForKey:@"tid_sum"];
             
             when = [self urldecode:[[rawDic objectForKey:@"lastreply"] objectForKey:@"when"]];
             who = [self urldecode:[[rawDic objectForKey:@"lastreply"] objectForKey:@"who"]];
             post.lastReply = [[BUCPost alloc] init];
             post.lastReply.user = [[NSAttributedString alloc] initWithString:who attributes:captionAttrs];
             post.lastReply.dateline = when;
             
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
- (NSAttributedString *)attributedStringFromHtml:(NSString *)html
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























