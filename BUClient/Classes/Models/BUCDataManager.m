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
#import "TFHpple.h"
#import "BUCPost.h"
#import "BUCPostFragment.h"

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
            
            post.title = [weakSelf titleFromHTML:[weakSelf urldecode:[rawDic objectForKey:@"pname"]]];
            
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
            post.title = [weakSelf titleFromHTML:[weakSelf urldecode:[rawDic objectForKey:@"subject"]]];
            post.content = [weakSelf fragmentsFromHTML:[weakSelf urldecode:[rawDic objectForKey:@"message"]]];
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

- (NSArray *)treeFromHTML:(NSString *)html
{
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    NSString *query = @"//body";
    NSArray *nodes = [[[parser searchWithXPathQuery:query] firstObject] children];
    
    return nodes;
}

- (NSArray *)fragmentsFromHTML:(NSString *)html
{
    NSArray *nodes = [self treeFromHTML:html];
    NSMutableArray *fragments = [[NSMutableArray alloc] init];
    BUCPostFragment *fragment = nil;
    BUCPostFragment *lastFragment = nil;
    NSString *tagName = nil;
    NSString *lastFragType = nil;
    
    NSString *utf8String = [[html stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"] stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    NSLog(@"\nRAW HTML======================================================================\n%@\n", utf8String);
    
    for (TFHppleElement *node in nodes)
    {
        tagName = node.tagName;
        
        if ([tagName isEqualToString:@"br"])
        {
            continue;
        }
        else if ([node isTextNode] ||
                 [tagName isEqualToString:@"p"] ||
                 [tagName isEqualToString:@"span"] ||
                 [tagName isEqualToString:@"a"] ||
                 [tagName isEqualToString:@"font"] ||
                 [tagName isEqualToString:@"b"] ||
                 [tagName isEqualToString:@"i"] ||
                 [tagName isEqualToString:@"u"])
        {
            if ([lastFragment.type isEqualToString:@"richText"])
            {
                [lastFragment.stringContent appendAttributedString:[self aStringFromHTML:node]];
                continue;
            }
            else
            {
                fragment = [[BUCPostFragment alloc] init];
                fragment.type = @"richText";
                fragment.stringContent = [[NSMutableAttributedString alloc] init];
                [fragment.stringContent appendAttributedString:[self aStringFromHTML:node]];
                lastFragType = @"richText";
            }
        }
        else if ([tagName isEqualToString:@"center"])
        {
            fragment = [[BUCPostFragment alloc] init];
            fragment.type = @"block";
            continue;
        }
        else if ([tagName isEqualToString:@"blockquote"])
        {
            
        }
        else if ([tagName isEqualToString:@"ol"])
        {
            
        }
        else if ([tagName isEqualToString:@"ul"])
        {
            
        }
        else
        {
            // unknown tag
            continue;
        }
        
        lastFragment = fragment;
        [fragments addObject:fragment];
    }
    
    for (BUCPostFragment *fragment in fragments)
    {
        NSLog(@"\nPARSE CONTENT===========================================================\n%@\n", [[fragment.stringContent.string stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"] stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]);
    }
    
    return fragments;
}

- (NSAttributedString *)aStringFromHTML:(TFHppleElement *)node
{
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] init];
    NSDictionary *attrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
    NSString *tagName = node.tagName;
    
    if ([tagName isEqualToString:@"text"])
    {
        [output appendAttributedString:[[NSAttributedString alloc] initWithString:[self replaceHtmlEntities:node.content] attributes:attrs]];
    }
    else if ([tagName isEqualToString:@"p"])
    {
        for (TFHppleElement *e in node.children)
        {
            if ([e.tagName isEqualToString:@"br"])
            {
                continue;
            }
            else
            {
                [output appendAttributedString:[self aStringFromHTML:e]];
            }
        }
    }
    else if ([tagName isEqualToString:@"img"])
    {
        
    }
    else if ([tagName isEqualToString:@"a"])
    {
        [output appendAttributedString:[self aStringFromA:node]];
    }
    else if ([tagName isEqualToString:@"font"])
    {
        [output appendAttributedString:[self aStringFromFont:node]];
    }
    else if ([tagName isEqualToString:@"b"])
    {
        [output appendAttributedString:[self aStringFromB:node]];
    }
    else if ([tagName isEqualToString:@"i"])
    {
        [output appendAttributedString:[self aStringFromI:node]];
    }
    else if ([tagName isEqualToString:@"u"])
    {
        [output appendAttributedString:[self aStringFromU:node]];
    }
    else if ([tagName isEqualToString:@"span"])
    {

    }
    else
    {
        NSLog(@"unknown tag type:%@", tagName);
    }
    
    
    return output;
}

- (NSAttributedString *)aStringFromU:(TFHppleElement *)u
{
    NSAttributedString *output = [[NSAttributedString alloc] initWithString:[self replaceHtmlEntities:u.firstChild.content]
                                                                 attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                                                              NSUnderlineStyleAttributeName:@1}];
    return output;
}

- (NSAttributedString *)aStringFromI:(TFHppleElement *)i
{
    NSAttributedString *output = [[NSAttributedString alloc] initWithString:[self replaceHtmlEntities:i.firstChild.content]
                                                                 attributes:[self createAttributesForFontStyle:UIFontTextStyleBody
                                                                                                     withTrait:UIFontDescriptorTraitItalic]];
    
    return output;
}

- (NSAttributedString *)aStringFromB:(TFHppleElement *)b
{
    NSAttributedString *output = [[NSAttributedString alloc] initWithString:[self replaceHtmlEntities:b.firstChild.content]
                                                                 attributes:[self createAttributesForFontStyle:UIFontTextStyleBody
                                                                                                     withTrait:UIFontDescriptorTraitBold]];
    
    return output;
}

- (NSDictionary*)createAttributesForFontStyle:(NSString*)style withTrait:(uint32_t)trait
{
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
    
    UIFontDescriptor *descriptorWithTrait = [fontDescriptor fontDescriptorWithSymbolicTraits:trait];
    
    UIFont* font =  [UIFont fontWithDescriptor:descriptorWithTrait size: 0.0];
    
    return @{NSFontAttributeName:font};
}


- (UIColor *)parseColorAttr:(NSString *)colorString
{
    static NSDictionary* colorTable = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorTable = @{
                         @"white":      [UIColor whiteColor],
                         @"black":      [UIColor blackColor],
                         @"red":        [UIColor redColor],
                         @"green":      [UIColor greenColor],
                         @"blue":       [UIColor blueColor],
                         @"yellow":     [UIColor yellowColor],
                         @"orange":     [UIColor orangeColor],
                         @"purple":     [UIColor purpleColor],
                         @"brown":      [UIColor brownColor],
                         @"pink":       [UIColor colorWithRed:1.0f green:192.0f/255.0f blue:203.0f/255.0f alpha:1.0f],
                         @"beige":      [UIColor colorWithRed:245.0f/255.0f green:245.0f/255.0f blue:220.0f/255.0f alpha:1.0f],
                         @"teal":       [UIColor colorWithRed:0 green:128.0f/255.0f blue:128.0f/255.0f alpha:1.0f],
                         @"navy":       [UIColor colorWithRed:0 green:0 blue:128.0f/255.0f alpha:1.0f],
                         @"maroon":     [UIColor colorWithRed:128.0f/255.0f green:0 blue:0 alpha:1.0f],
                         @"limegreen":  [UIColor colorWithRed:50.0f/255.0f green:205.0f/255.0f blue:50.0f/255.0f alpha:1.0f],
                         @"#CC3333":    [UIColor colorWithRed:204.0f/255.0f green:51.0f/255.0f blue:0 alpha:1.0f]
                         };
    });
    
    UIColor *output = [colorTable objectForKey:[colorString lowercaseString]];
    
    if (output)
    {
        return output;
    }
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^#([a-zA-Z0-9]{3}|[a-zA-Z0-9]{6})$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:colorString
                                                        options:0
                                                          range:NSMakeRange(0, [colorString length])];
    
    if (numberOfMatches == 0)
    {
        output = [UIColor blackColor];
    }
    else
    {
        NSString *cleanString = [colorString stringByReplacingOccurrencesOfString:@"#" withString:@""];
        if([cleanString length] == 3) {
            cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                           [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                           [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                           [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
        }
        
        unsigned int baseValue;
        [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
        
        output = [UIColor colorWithRed:((baseValue >> 24) & 0xFF)/255.0f green:((baseValue >> 16) & 0xFF)/255.0f blue:((baseValue >> 8) & 0xFF)/255.0f alpha:1.0f];
    }
    
    return output;
}

- (NSAttributedString *)aStringFromFont:(TFHppleElement *)font
{
    NSString *content = font.firstChild.content;
    NSMutableDictionary *attrs = [[NSMutableDictionary alloc] init];
    [attrs setObject:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] forKey:NSFontAttributeName];
    NSString *colorString = [font objectForKey:@"color"];
    if (colorString != nil)
    {
        UIColor *color = [self parseColorAttr:[font objectForKey:@"color"]];
        [attrs setObject:color forKey:NSForegroundColorAttributeName];
    }

    NSAttributedString *output = [[NSAttributedString alloc] initWithString:[self replaceHtmlEntities:content] attributes:attrs];
    
    return output;
}

- (NSAttributedString *)aStringFromA:(TFHppleElement *)a
{
    NSAttributedString *output = nil;
    NSString *href = [a objectForKey:@"href"];
    NSString *content = [[a firstChild] content];
    NSDictionary *attrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] ,NSLinkAttributeName:href};
    output = [[NSAttributedString alloc] initWithString:[self replaceHtmlEntities:content] attributes:attrs];
    
    return output;
}

- (NSAttributedString *)titleFromHTML:(NSString *)html
{
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] init];
    NSArray *nodes = [self treeFromHTML:html];
    
    for (TFHppleElement *node in nodes)
    {
        [output appendAttributedString:[self aStringFromHTML:node]];
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
    return [[[[[string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"]
               stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "]
              stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""]
             stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"]
            stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
}

@end























