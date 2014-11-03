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
//        int i = 0;
        for (NSDictionary *rawDic in rawArray)
        {
//            NSLog(@"\n%d楼\n", i + 1);
//            i = i + 1;
            post = [[BUCPost alloc] init];
            
            post.pid = [rawDic objectForKey:@"pid"];
            post.fid = [rawDic objectForKey:@"fid"];
            
            post.user = [[NSAttributedString alloc] initWithString:[weakSelf urldecode:[rawDic objectForKey:@"author"]]
                                                        attributes:captionAttrs];
            post.uid = [rawDic objectForKey:@"authorid"];
            post.title = [weakSelf titleFromHTML:[weakSelf urldecode:[rawDic objectForKey:@"subject"]]];
            post.fragments = [weakSelf fragmentsFromHTML:[weakSelf urldecode:[rawDic objectForKey:@"message"]]];
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

#pragma mark - networking
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

#pragma mark - parsing
- (NSArray *)fragmentsFromHTML:(NSString *)html
{
//    NSString *utf8String = [[html stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"] stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
//    NSLog(@"\nRAW HTML======================================================================\n%@\n", utf8String);
    
    NSArray *fragments = [self fragmentsFromTree:[self treeFromHTML:html]];
    
//    for (BUCPostFragment *fragment in fragments)
//    {
//        [self printOutTree:fragment];
//    }
    
    return fragments;
}

- (void)printOutTree:(BUCPostFragment *)tree
{
    NSLog(@"=========================entering tree...=========================\n");
    if (tree.isRichText)
    {
        NSLog(@"\n%@\n", tree.richText);
    }
    else if (tree.isBlock)
    {
        for (BUCPostFragment *fragment in tree.children)
        {
            [self printOutTree:fragment];
        }
    }
    else if (tree.isImage)
    {
        NSLog(@"\n%@\n", tree.imageURL);
    }
    else
    {
        NSLog(@"WARNING -- unknown tag!");
    }
    
    NSLog(@"=========================leaving tree...============================\n");
}

- (NSArray *)treeFromHTML:(NSString *)html
{
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    NSString *query = @"//body";
    NSArray *nodes = [[[parser searchWithXPathQuery:query] firstObject] children];
    
    return nodes;
}

- (NSArray *)fragmentsFromTree:(NSArray *)tree
{
    NSMutableArray *fragments = [[NSMutableArray alloc] init];
    BUCPostFragment *fragment = nil;
    BUCPostFragment *lastFragment = nil;
    NSString *tagName = nil;
    
    for (TFHppleElement *node in tree)
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
            if (lastFragment.isRichText)
            {
                [lastFragment.richText appendAttributedString:[self richTextFromTree:node]];
                continue;
            }
            else
            {
                fragment = [[BUCPostFragment alloc] init];
                fragment.isRichText = YES;
                fragment.richText = [[NSMutableAttributedString alloc] initWithString:@""];
                [fragment.richText appendAttributedString:[self richTextFromTree:node]];
            }
        }
        else if ([tagName isEqualToString:@"center"])
        {
            fragment = [self fragmentFromCenter:node];
            fragment.isBlock = YES;
        }
        else if ([tagName isEqualToString:@"img"])
        {
            fragment = [self fragmentFromImage:node];
            fragment.isImage = YES;
        }
        else if ([tagName isEqualToString:@"blockquote"])
        {
            fragment = [self fragmentFromBox:node];
            fragment.isBlock = YES;
        }
        else if ([tagName isEqualToString:@"ol"] || [tagName isEqualToString:@"ul"])
        {
            fragment = [self fragmentFromList:node];
            fragment.isBlock = YES;
        }
        else
        {
            // unknown tag
            continue;
        }
        
        if (fragment != nil)
        {
            lastFragment = fragment;
            [fragments addObject:fragment];
        }
    }
    
    return fragments;
}

- (NSAttributedString *)richTextFromTree:(TFHppleElement *)tree
{
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@""];
    NSString *tagName = tree.tagName;
    
    if ([tree isTextNode] == YES)
    {
        [output appendAttributedString:[self richTextFromText:tree]];
    }
    else if ([tagName isEqualToString:@"p"])
    {
        for (TFHppleElement *e in tree.children)
        {
            if ([e.tagName isEqualToString:@"br"])
            {
                continue;
            }
            else
            {
                [output appendAttributedString:[self richTextFromTree:e]];
            }
        }
    }
    else if ([tagName isEqualToString:@"img"])
    {
        // img needed to be supported
        [output appendAttributedString:[[NSAttributedString alloc] initWithString:@""]];
    }
    else if ([tagName isEqualToString:@"a"])
    {
        [output appendAttributedString:[self richTextFromA:tree]];
    }
    else if ([tagName isEqualToString:@"font"])
    {
        [output appendAttributedString:[self richTextFromFont:tree]];
    }
    else if ([tagName isEqualToString:@"b"])
    {
        [output appendAttributedString:[self richTextFromB:tree]];
    }
    else if ([tagName isEqualToString:@"i"])
    {
        [output appendAttributedString:[self richTextFromI:tree]];
    }
    else if ([tagName isEqualToString:@"u"])
    {
        [output appendAttributedString:[self richTextFromU:tree]];
    }
    else if ([tagName isEqualToString:@"span"])
    {
        [output appendAttributedString:[self richTextFromSpan:tree]];
    }
    else
    {
        NSLog(@"unknown tag type:%@", tagName);
    }
    
    
    return output;
}

#pragma mark - block html element parsing
- (BUCPostFragment *)fragmentFromImage:(TFHppleElement *)image
{
    BUCPostFragment *fragment = [[BUCPostFragment alloc] init];
    fragment.imageURL = [image objectForKey:@"src"];
    
    return fragment;
}

- (BUCPostFragment *)fragmentFromCenter:(TFHppleElement *)center
{
    NSString *query = @"//center/table/tr/td";
    NSArray *nodes = [center searchWithXPathQuery:query];
    NSString *typeString = [[[nodes firstObject] firstChild] content];
    query = @"//table/tr/td/table/tr/td";
    nodes = [center searchWithXPathQuery:query];
    TFHppleElement *content = [nodes firstObject];
    BUCPostFragment *fragment = [[BUCPostFragment alloc] init];
    if ([typeString rangeOfString:@"引用"].length != 0)
    {
        fragment.children = [self fragmentsFromTree:content.children];
        return fragment;
    }
    else if ([typeString rangeOfString:@"代码"].length != 0)
    {
        return [self fragmentFromCode:content];
    }
    else
    {
        // unknown center block
        NSLog(@"unknown center block:%@", center.raw);
        return nil;
    }
}

- (BUCPostFragment *)fragmentFromCode:(TFHppleElement *)codeBlock
{
    NSString *query = @"//div/ol/li";
    NSArray *codeLines = [codeBlock searchWithXPathQuery:query];
    
    BUCPostFragment *fragment = [[BUCPostFragment alloc] init];
    NSDictionary *attrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
    NSMutableAttributedString *richText = [[NSMutableAttributedString alloc] initWithString:@""];
    NSString *buffer = nil;
    
    for (TFHppleElement *line in codeLines)
    {
        buffer = [NSString stringWithFormat:@"%@\n", line.firstChild.content];
        [richText appendAttributedString:[[NSAttributedString alloc] initWithString:buffer attributes:attrs]];
    }
    
    fragment.richText = richText;
    
    return fragment;
}

- (BUCPostFragment *)fragmentFromBox:(TFHppleElement *)box
{
    NSString *query = @"//blockquote/div";
    NSArray *nodes = [box searchWithXPathQuery:query];
    BUCPostFragment *fragment = [[BUCPostFragment alloc] init];
    fragment.children = [self fragmentsFromTree:[[nodes lastObject] children]];
    
    return fragment;
}

- (BUCPostFragment *)fragmentFromList:(TFHppleElement *)list
{
    NSString *query = @"//li";
    NSArray *nodes = [list searchWithXPathQuery:query];
    NSMutableAttributedString *richText = [[NSMutableAttributedString alloc] initWithString:@""];
    NSDictionary *attrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
    NSString *buffer = nil;
    BUCPostFragment *fragment = [[BUCPostFragment alloc] init];
    
    for (TFHppleElement *node in nodes)
    {
        buffer = [NSString stringWithFormat:@"• %@\n", node.firstChild.content];
        [richText appendAttributedString:[[NSAttributedString alloc] initWithString:buffer attributes:attrs]];
    }
    
    fragment.richText = richText;
 
    return fragment;
}

#pragma mark - inline html element parsing
- (NSAttributedString *)titleFromHTML:(NSString *)html
{
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@""];
    NSArray *nodes = [self treeFromHTML:html];
    
    for (TFHppleElement *node in nodes)
    {
        [output appendAttributedString:[self richTextFromTree:node]];
    }
    
    return output;
}

- (NSAttributedString *)richTextFromText:(TFHppleElement *)text
{
    // strike tag and video tag needed to be suppported
    NSDictionary *attrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
    return [[NSAttributedString alloc] initWithString:[self replaceHtmlEntities:text.content] attributes:attrs];
}

- (NSAttributedString *)richTextFromSpan:(TFHppleElement *)span
{
    if ([[span objectForKey:@"id"] isEqualToString:@"id_open_api_label"])
    {
        NSString *url = @"http://out.bitunion.org/thread-10471436-1-1.html";
        NSDictionary *attrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
        NSDictionary *linkAttrs = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody], NSLinkAttributeName:url};
        NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@"..::" attributes:attrs];
        [output appendAttributedString:[[NSAttributedString alloc] initWithString:@"From BIT-Union Open API Project" attributes:linkAttrs]];
        [output appendAttributedString:[[NSAttributedString alloc] initWithString:@"::.." attributes:attrs]];
        return output;
    }
    else
    {
        NSLog(@"unknown tag:%@", span.raw);
        return [[NSAttributedString alloc] initWithString:@""];
    }
}

- (NSAttributedString *)richTextFromFont:(TFHppleElement *)font
{
    // ignore custom size text, only process colored text
    NSMutableDictionary *attrs = [[NSMutableDictionary alloc] init];
    [attrs setObject:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] forKey:NSFontAttributeName];
    NSString *colorString = [font objectForKey:@"color"];
    if (colorString != nil)
    {
        UIColor *color = [self parseColorAttr:[font objectForKey:@"color"]];
        [attrs setObject:color forKey:NSForegroundColorAttributeName];
    }
    
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@""];
    
    for (TFHppleElement *node in font.children)
    {
        if ([node isTextNode])
        {
            [output appendAttributedString:[[NSAttributedString alloc] initWithString:node.content attributes:attrs]];
        }
        else if ([node.tagName isEqualToString:@"a"])
        {
            [output appendAttributedString:[self richTextFromA:node]];
        }
        else
        {
            // unknown tag
            continue;
        }
    }

    return output;
}

- (NSAttributedString *)richTextFromA:(TFHppleElement *)a
{
    NSAttributedString *output = nil;
    NSString *href = [a objectForKey:@"href"];
    NSString *content = [self replaceHtmlEntities:[[a firstChild] content]];
    
    NSError *error = nil;
    NSRegularExpression *summonRegex = [NSRegularExpression
                                        regularExpressionWithPattern:@"^/profile-username-.+\\.html$"
                                        options:NSRegularExpressionCaseInsensitive
                                        error:&error];
    
    NSRegularExpression *mailRegex = [NSRegularExpression
                                      regularExpressionWithPattern:@"^mailto:.+$"
                                      options:NSRegularExpressionCaseInsensitive
                                      error:&error];
    
    if ([summonRegex numberOfMatchesInString:href options:0 range:NSMakeRange(0, [href length])])
    {
        output = [[NSAttributedString alloc] initWithString:content
                                                 attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                                              @"BUCSummonLink":content}];
    }
    else if ([mailRegex numberOfMatchesInString:href options:0 range:NSMakeRange(0, [href length])])
    {
        output = [[NSAttributedString alloc] initWithString:content
                                                 attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                                              @"BUCMailLink":[href substringFromIndex:7]}];
    }
    else
    {
        output = [[NSAttributedString alloc] initWithString:content
                                                 attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                                              NSLinkAttributeName:href}];
    }
    
    return output;
}

- (NSAttributedString *)richTextFromU:(TFHppleElement *)u
{
    NSAttributedString *output = [[NSAttributedString alloc] initWithString:[self replaceHtmlEntities:u.firstChild.content]
                                                                 attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                                                              NSUnderlineStyleAttributeName:@1}];
    return output;
}

- (NSAttributedString *)richTextFromI:(TFHppleElement *)i
{
    NSAttributedString *output = [[NSAttributedString alloc] initWithString:[self replaceHtmlEntities:i.firstChild.content]
                                                                 attributes:[self createAttributesForFontStyle:UIFontTextStyleBody
                                                                                                     withTrait:UIFontDescriptorTraitItalic]];
    
    return output;
}

- (NSAttributedString *)richTextFromB:(TFHppleElement *)b
{
    NSAttributedString *output = [[NSAttributedString alloc] initWithString:[self replaceHtmlEntities:b.firstChild.content]
                                                                 attributes:[self createAttributesForFontStyle:UIFontTextStyleBody
                                                                                                     withTrait:UIFontDescriptorTraitBold]];
    
    return output;
}

#pragma mark - utilies
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
                       @"#cc3333":    [UIColor colorWithRed:204.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1.0f]
                       };
    });
    
    UIColor *output = [colorTable objectForKey:[colorString lowercaseString]];
    
    if (output)
    {
        return output;
    }
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^#([a-z0-9]{3}|[a-z0-9]{6})$" options:NSRegularExpressionCaseInsensitive error:&error];
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
        
        output = [UIColor colorWithRed:((baseValue >> 16) & 0xFF)/255.0f green:((baseValue >> 8) & 0xFF)/255.0f blue:(baseValue & 0xFF)/255.0f alpha:1.0f];
    }
    
    return output;
}

- (NSDictionary*)createAttributesForFontStyle:(NSString*)style withTrait:(uint32_t)trait
{
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
    
    UIFontDescriptor *descriptorWithTrait = [fontDescriptor fontDescriptorWithSymbolicTraits:trait];
    
    UIFont* font =  [UIFont fontWithDescriptor:descriptorWithTrait size: 0.0];
    
    return @{NSFontAttributeName:font};
}

@end



















