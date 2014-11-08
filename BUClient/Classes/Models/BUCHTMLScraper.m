#import "BUCHTMLScraper.h"
#import "BUCPostFragment.h"
#import "TFHpple.h"


@implementation BUCHTMLScraper


#pragma mark - public interface
- (NSAttributedString *)titleFromHTML:(NSString *)html{
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@""];
    NSArray *nodes = [self treeFromHTML:html];
    
    for (TFHppleElement *node in nodes) {
        [output appendAttributedString:[self richTextFromTree:node]];
    }
    
    return output;
}


- (NSArray *)fragmentsFromHTML:(NSString *)html {
    return [self fragmentsFromTree:[self treeFromHTML:html]];
}


- (NSString *)imageURLFromHTML:(NSString *)html
{
    if (html.length == 0) {
        return @"";
    }
    
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    NSString *query = @"//body";
    NSArray *nodes = [[[parser searchWithXPathQuery:query] firstObject] children];
    NSString *url = [[nodes firstObject] objectForKey:@"src"];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^http://www\\.bitunion\\.org/.+$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:url options:0 range:NSMakeRange(0, url.length)];
    if (numberOfMatches > 0) {
        url = [url stringByReplacingOccurrencesOfString:@"www.bitunion.org" withString:@"out.bitunion.org"];
    }
    
    return url;
}


#pragma mark - top level tree
- (NSArray *)treeFromHTML:(NSString *)html {
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    NSString *query = @"//body";
    NSArray *nodes = [[[parser searchWithXPathQuery:query] firstObject] children];
    
    return nodes;
}


- (NSArray *)fragmentsFromTree:(NSArray *)tree {
    NSMutableArray *fragments = [[NSMutableArray alloc] init];
    BUCPostFragment *lastFragment;
    
    for (TFHppleElement *node in tree) {
        BUCPostFragment *fragment;
        NSString *tagName = node.tagName;
        
        if ([tagName isEqualToString:@"br"]) {
            continue;
        } else if ([node isTextNode] ||
                   [tagName isEqualToString:@"p"] ||
                   [tagName isEqualToString:@"img"] ||
                   [tagName isEqualToString:@"span"] ||
                   [tagName isEqualToString:@"a"] ||
                   [tagName isEqualToString:@"font"] ||
                   [tagName isEqualToString:@"b"] ||
                   [tagName isEqualToString:@"i"] ||
                   [tagName isEqualToString:@"u"]) {
            
            if (![tagName isEqualToString:@"p"] &&
                (![node.firstChild isTextNode] ||
                 [node.children count] != 1)) {
                    
                    // if inline element has block element child, then it's invalid, don't parse it
                    continue;
                }
            
            if (lastFragment.isRichText) {
                [lastFragment.richText appendAttributedString:[self richTextFromTree:node]];
                continue;
            } else {
                fragment = [[BUCPostFragment alloc] init];
                fragment.isRichText = YES;
                fragment.richText = [[NSMutableAttributedString alloc] initWithString:@""];
                [fragment.richText appendAttributedString:[self richTextFromTree:node]];
            }
        } else if ([tagName isEqualToString:@"center"]) {
            fragment = [self fragmentFromCenter:node];
            fragment.isBlock = YES;
        } else if ([tagName isEqualToString:@"blockquote"]) {
            fragment = [self fragmentFromBox:node];
            fragment.isBlock = YES;
        } else if ([tagName isEqualToString:@"ol"] || [tagName isEqualToString:@"ul"]) {
            fragment = [self fragmentFromList:node];
            fragment.isBlock = YES;
        } else {
            // unknown tag
            continue;
        }
        
        if (fragment != nil) {
            lastFragment = fragment;
            [fragments addObject:fragment];
        }
    }
    
    return fragments;
}


- (NSAttributedString *)richTextFromTree:(TFHppleElement *)tree {
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@""];
    NSString *tagName = tree.tagName;
    
    if ([tree isTextNode] == YES) {
        [output appendAttributedString:[self richTextFromText:tree]];
    } else if ([tagName isEqualToString:@"p"]) {
        for (TFHppleElement *e in tree.children) {
            if ([e.tagName isEqualToString:@"br"]) {
                continue;
            } else {
                [output appendAttributedString:[self richTextFromTree:e]];
            }
        }
    } else if ([tagName isEqualToString:@"img"]) {
        [output appendAttributedString:[self richTextFromImage:tree]];
    } else if ([tagName isEqualToString:@"a"]) {
        [output appendAttributedString:[self richTextFromA:tree]];
    } else if ([tagName isEqualToString:@"font"]) {
        [output appendAttributedString:[self richTextFromFont:tree]];
    } else if ([tagName isEqualToString:@"b"]) {
        [output appendAttributedString:[self richTextFromB:tree]];
    } else if ([tagName isEqualToString:@"i"]) {
        [output appendAttributedString:[self richTextFromI:tree]];
    } else if ([tagName isEqualToString:@"u"]) {
        [output appendAttributedString:[self richTextFromU:tree]];
    } else if ([tagName isEqualToString:@"span"]) {
        [output appendAttributedString:[self richTextFromSpan:tree]];
    } else {
        NSLog(@"unknown tag type:%@", tagName);
    }
    
    
    return output;
}


#pragma mark - block element
- (BUCPostFragment *)fragmentFromCenter:(TFHppleElement *)center {
    NSString *query = @"//center/table/tr/td";
    NSArray *nodes = [center searchWithXPathQuery:query];
    NSString *typeString = [[[nodes firstObject] firstChild] content];
    query = @"//table/tr/td/table/tr/td";
    nodes = [center searchWithXPathQuery:query];
    TFHppleElement *content = [nodes firstObject];
    BUCPostFragment *fragment = [[BUCPostFragment alloc] init];
    if ([typeString rangeOfString:@"引用"].length != 0) {
        fragment.children = [self fragmentsFromTree:[self removeImageFromTree:content.children]];
        return fragment;
    } else if ([typeString rangeOfString:@"代码"].length != 0) {
        return [self fragmentFromCode:content];
    } else {
        // unknown center block
        NSLog(@"unknown center block:%@", center.raw);
        return nil;
    }
}


- (NSArray *)removeImageFromTree:(NSArray *)tree{
    // we don't want render images in block element
    NSMutableArray *output = [[NSMutableArray alloc] init];
    
    for (TFHppleElement *node in tree) {
        if ([node.tagName isEqualToString:@"img"]) {
            continue;
        } else {
            [output addObject:node];
        }
    }
    
    return output;
}


- (BUCPostFragment *)fragmentFromCode:(TFHppleElement *)codeBlock {
    NSString *query = @"//div/ol/li";
    NSArray *codeLines = [codeBlock searchWithXPathQuery:query];
    
    BUCPostFragment *fragment = [[BUCPostFragment alloc] init];
    NSDictionary *attrs = [self attributesForFontStyle:UIFontTextStyleBody];
    NSMutableAttributedString *richText = [[NSMutableAttributedString alloc] initWithString:@""];
    
    for (TFHppleElement *line in codeLines) {
        NSString *buffer = [NSString stringWithFormat:@"%@\n", line.firstChild.content];
        [richText appendAttributedString:[[NSAttributedString alloc] initWithString:buffer attributes:attrs]];
    }
    
    fragment.richText = richText;
    
    return fragment;
}


- (BUCPostFragment *)fragmentFromBox:(TFHppleElement *)box {
    NSString *query = @"//blockquote/div";
    NSArray *nodes = [box searchWithXPathQuery:query];
    BUCPostFragment *fragment = [[BUCPostFragment alloc] init];
    fragment.children = [self fragmentsFromTree:[self removeImageFromTree:[[nodes lastObject] children]]];
    
    return fragment;
}


- (BUCPostFragment *)fragmentFromList:(TFHppleElement *)list {
    NSString *query = @"//li";
    NSArray *nodes = [list searchWithXPathQuery:query];
    NSMutableAttributedString *richText = [[NSMutableAttributedString alloc] initWithString:@""];
    NSDictionary *attrs = [self attributesForFontStyle:UIFontTextStyleBody];
    
    for (TFHppleElement *node in nodes) {
        if (![node.firstChild isTextNode]) {
            // we don't render elements other than text in list block
            continue;
        }
        
        NSString *buffer = [NSString stringWithFormat:@"• %@\n", node.firstChild.content];
        [richText appendAttributedString:[[NSAttributedString alloc] initWithString:buffer attributes:attrs]];
    }
    
    BUCPostFragment *fragment = [[BUCPostFragment alloc] init];
    fragment.richText = richText;
    
    return fragment;
}


#pragma mark - inline element
- (NSAttributedString *)richTextFromText:(TFHppleElement *)text {
    // strike and video tag needed to be suppported
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:[self replaceHtmlEntities:text.content] attributes:[self attributesForFontStyle:UIFontTextStyleBody]];
    
    return output;
}


- (NSAttributedString *)richTextFromImage:(TFHppleElement *)image {
    NSString *imageURL = [image objectForKey:@"src"];
    NSLog(@"image:%@", imageURL);
    // parse the image url....
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [UIImage imageNamed:imageURL];
    NSAttributedString *output = [NSAttributedString attributedStringWithAttachment:attachment];
    return output;
}


- (NSAttributedString *)richTextFromSpan:(TFHppleElement *)span {
    if ([[span objectForKey:@"id"] isEqualToString:@"id_open_api_label"]) {
        NSString *url = @"http://out.bitunion.org/thread-10471436-1-1.html";
        NSDictionary *attributes = [self attributesForFontStyle:UIFontTextStyleBody];
        NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@"..::" attributes:attributes];
        NSMutableAttributedString *link = [[NSMutableAttributedString alloc] initWithString:@"From BIT-Union Open API Project" attributes:attributes];
        [link addAttribute:NSLinkAttributeName value:url range:NSMakeRange(0, link.length)];
        [output appendAttributedString:link];
        [output appendAttributedString:[[NSAttributedString alloc] initWithString:@"::.." attributes:attributes]];
        return output;
    } else {
        NSLog(@"unknown tag:%@", span.raw);
        return [[NSAttributedString alloc] initWithString:@""];
    }
}


- (NSAttributedString *)richTextFromFont:(TFHppleElement *)font {
    NSString *content = [self replaceHtmlEntities:font.firstChild.content];
    NSMutableDictionary *attributes = [self attributesForFontStyle:UIFontTextStyleBody];
    if (!attributes) {
        NSLog(@"attributes is nil");
    }
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@""];
    
    // ignore custom size text, only process colored text
    NSString *colorString = [font objectForKey:@"color"];
    if (colorString != nil) {
        UIColor *color = [self parseColorAttr:colorString];
        [attributes setObject:color forKey:NSForegroundColorAttributeName];
    }
    
    [output appendAttributedString:[[NSAttributedString alloc] initWithString:content attributes:attributes]];
    
    return output;
}


- (NSAttributedString *)richTextFromA:(TFHppleElement *)a {
    NSString *content = [self replaceHtmlEntities:a.firstChild.content];
    NSMutableDictionary *attributes = [self attributesForFontStyle:UIFontTextStyleBody];
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@""];
    
    NSString *href = [a objectForKey:@"href"];
    NSError *error;
    NSRegularExpression *summonRegex = [NSRegularExpression
                                        regularExpressionWithPattern:@"^/profile-username-.+\\.html$"
                                        options:NSRegularExpressionCaseInsensitive
                                        error:&error];
    
    NSRegularExpression *mailRegex = [NSRegularExpression
                                      regularExpressionWithPattern:@"^mailto:.+$"
                                      options:NSRegularExpressionCaseInsensitive
                                      error:&error];
    
    if ([summonRegex numberOfMatchesInString:href options:0 range:NSMakeRange(0, href.length)]) {
        [attributes setObject:content forKey:@"BUCSummonLink"];
    } else if ([mailRegex numberOfMatchesInString:href options:0 range:NSMakeRange(0, href.length)]) {
        [attributes setObject:[href substringFromIndex:7] forKey:@"BUCMailLink"];
    } else {
        [attributes setObject:href forKey:NSLinkAttributeName];
    }
    
    [output appendAttributedString:[[NSAttributedString alloc] initWithString:content attributes:attributes]];
    
    return output;
}


- (NSAttributedString *)richTextFromU:(TFHppleElement *)u {
    NSString *content = [self replaceHtmlEntities:u.firstChild.content];
    NSMutableDictionary *attributes = [self attributesForFontStyle:UIFontTextStyleBody];
    [attributes setObject:@1 forKey:NSUnderlineStyleAttributeName];
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:content attributes:attributes];
    
    return output;
}


- (NSAttributedString *)richTextFromI:(TFHppleElement *)i {
    NSString *content = [self replaceHtmlEntities:i.firstChild.content];
    NSDictionary *attributes = [self attributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitItalic];
    NSAttributedString *output = [[NSAttributedString alloc] initWithString:content attributes:attributes];
    
    return output;
}


- (NSAttributedString *)richTextFromB:(TFHppleElement *)b {
    NSString *content = [self replaceHtmlEntities:b.firstChild.content];
    NSDictionary *attributes = [self attributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitBold];
    NSAttributedString *output = [[NSAttributedString alloc] initWithString:content attributes:attributes];
    
    return output;
}


#pragma mark - utilies
- (NSString *)replaceHtmlEntities:(NSString *)string {
    return [[[[[string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"]
               stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "]
              stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""]
             stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"]
            stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
}


- (UIColor *)parseColorAttr:(NSString *)colorString {
    static NSDictionary* colorTable;
    
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
    
    if (output) {
        return output;
    }
    
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^#([a-z0-9]{3}|[a-z0-9]{6})$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:colorString
                                                        options:0
                                                          range:NSMakeRange(0, [colorString length])];
    
    if (numberOfMatches == 0) {
        output = [UIColor blackColor];
    } else {
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


- (NSDictionary *)attributesForFontStyle:(NSString*)style withTrait:(uint32_t)trait {
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
    
    UIFontDescriptor *descriptorWithTrait = [fontDescriptor fontDescriptorWithSymbolicTraits:trait];
    
    UIFont *font =  [UIFont fontWithDescriptor:descriptorWithTrait size: 0.0];
    
    return @{NSFontAttributeName:font};
}


- (NSMutableDictionary *)attributesForFontStyle:(NSString *)style {
    return [[NSMutableDictionary alloc] initWithObjectsAndKeys:[UIFont preferredFontForTextStyle:style], NSFontAttributeName, nil];
}


@end


















