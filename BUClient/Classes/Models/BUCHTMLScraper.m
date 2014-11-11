#import "BUCHTMLScraper.h"
#import "BUCPostFragment.h"
#import "TFHpple.h"
#import "BUCImage.h"
#import "UIImage+animatedGIF.h"


@implementation BUCHTMLScraper


#pragma mark - public interface
- (NSAttributedString *)titleFromHTML:(NSString *)html{
    BUCPostFragment *title = [[self fragmentsFromHTML:html] lastObject];
    
    return title.richText;
}


- (NSArray *)fragmentsFromHTML:(NSString *)html {
    return [self fragmentsFromTree:[self treeFromHTML:html]];
}


- (NSString *)avatarURLFromHTML:(NSString *)html
{
    if (html.length == 0) {
        return @"";
    }
    
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    NSString *query = @"//body";
    NSArray *nodes = [[[parser searchWithXPathQuery:query] firstObject] children];
    NSString *url = [[nodes firstObject] objectForKey:@"src"];
    NSRegularExpression *regex = [self regexFromPattern:@"^http://www\\.bitunion\\.org/.+$"];
    NSRegularExpression *relativeRegex = [self regexFromPattern:@"^images/.+$"];
    if ([self matchString:url withRegex:regex]) {
        url = [url stringByReplacingOccurrencesOfString:@"www.bitunion.org" withString:@"out.bitunion.org"];
    } else if ([self matchString:url withRegex:relativeRegex]) {
        url = [NSString stringWithFormat:@"%@/%@", @"http://out.bitunion.org", url];
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
        } else if ([tagName isEqualToString:@"p"]) {
            fragment = [self fragmentFromP:node];
            
        } else if ([node isTextNode] ||
                   [tagName isEqualToString:@"span"] ||
                   [tagName isEqualToString:@"a"] ||
                   [tagName isEqualToString:@"font"] ||
                   [tagName isEqualToString:@"b"] ||
                   [tagName isEqualToString:@"i"] ||
                   [tagName isEqualToString:@"u"]) {
            
            if (lastFragment.isRichText) {
                [lastFragment.richText appendAttributedString:[self richTextFromTree:node]];
                continue;
            } else {
                fragment = [[BUCPostFragment alloc] init];
                fragment.isRichText = YES;
                fragment.richText = [[NSMutableAttributedString alloc] initWithString:@""];
                [fragment.richText appendAttributedString:[self richTextFromTree:node]];
            }
            
        } else if ([tagName isEqualToString:@"img"]) {
            BUCImage *image = [self imageFromImageNode:node];
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            UIImage *foo = image.image;
            attachment.bounds = CGRectMake(2.0f, 2.0f, foo.size.width, foo.size.height);
            attachment.bounds = (CGRect){(CGPoint){0,0}, image.image.size};
            attachment.image = image.image;
            NSAttributedString *richText = [NSAttributedString attributedStringWithAttachment:attachment];
            if (lastFragment.isRichText) {
                image.glyphIndex = lastFragment.richText.length;
                [lastFragment.richText appendAttributedString:richText];
                [lastFragment addImage:image];
                continue;
            } else {                
                fragment = [[BUCPostFragment alloc] init];
                fragment.isRichText = YES;
                fragment.richText = [[NSMutableAttributedString alloc] initWithString:@""];
                [fragment.richText appendAttributedString:richText];
                image.glyphIndex = 0;
                [fragment addImage:image];
            }
            
        } else if ([tagName isEqualToString:@"center"]) {
            fragment = [self fragmentFromCenter:node];
        } else if ([tagName isEqualToString:@"blockquote"]) {
            fragment = [self fragmentFromBox:node];
        } else if ([tagName isEqualToString:@"ol"] || [tagName isEqualToString:@"ul"]) {
            fragment = [self fragmentFromList:node];
        } else {
            NSLog(@"unknown tag:%@", tagName);
            // unknown tag
            continue;
        }
        
        if (fragment) {
            lastFragment = fragment;
            [fragments addObject:fragment];
        }
    }
    
    return fragments;
}


- (NSMutableAttributedString *)richTextFromTree:(TFHppleElement *)tree {
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@""];
    NSDictionary *attributes;
    NSString *tagName = tree.tagName;
    
    if ([tree isTextNode] == YES) {
        [output appendAttributedString:[self richTextFromText:tree]];
        return output;
    } else if ([tagName isEqualToString:@"a"]) {
        attributes = [self attributesFromA:tree];
    } else if ([tagName isEqualToString:@"font"]) {
        attributes = [self attributesFromFont:tree];
    } else if ([tagName isEqualToString:@"b"]) {
        attributes = [self attributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitBold];
    } else if ([tagName isEqualToString:@"i"]) {
        attributes = [self attributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitItalic];
    } else if ([tagName isEqualToString:@"u"]) {
        attributes = @{NSUnderlineStyleAttributeName:@1};
    } else if ([tagName isEqualToString:@"span"]) {
        [output appendAttributedString:[self richTextFromSpan:tree]];
        return output;
    } else {
        NSLog(@"unknown tag type:%@", tagName);
    }
    
    for (TFHppleElement *node in tree.children) {
        if ([self isBlockElement:node] || [node.tagName isEqualToString:@"br"]) {
            continue;
        }
        
        NSMutableAttributedString *richText = [self richTextFromTree:node];
        if (attributes) {
            [self addAttributes:attributes toRichText:richText];
        }
        [output appendAttributedString:richText];
    }
    
    return output;
}


#pragma mark - block element
- (BUCPostFragment *)fragmentFromP:(TFHppleElement *)p {
    BUCPostFragment *fragment = [[BUCPostFragment alloc] init];
    fragment.isRichText = YES;
    fragment.richText = [[NSMutableAttributedString alloc] initWithString:@""];
    
    for (TFHppleElement *node in p.children) {
        if ([node.tagName isEqualToString:@"br"]) {
            continue;
        } else if ([node.tagName isEqualToString:@"img"]) {
            BUCImage *image = [self imageFromImageNode:node];
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
//            attachment.bounds = image.bounds;
            attachment.image = image.image;
            NSAttributedString *richText = [NSAttributedString attributedStringWithAttachment:attachment];
            image.glyphIndex = fragment.richText.length;
            [fragment.richText appendAttributedString:richText];
            [fragment addImage:image];
        } else {
            [fragment.richText appendAttributedString:[self richTextFromTree:node]];
        }
    }
    
    return fragment;
}


- (BUCPostFragment *)fragmentFromCenter:(TFHppleElement *)center {
    NSString *query = @"//center/table/tr/td";
    NSArray *nodes = [center searchWithXPathQuery:query];
    NSString *typeString = [[[nodes firstObject] firstChild] content];
    query = @"//table/tr/td/table/tr/td";
    nodes = [center searchWithXPathQuery:query];
    TFHppleElement *content = [nodes firstObject];
    BUCPostFragment *fragment = [[BUCPostFragment alloc] init];

    if ([typeString rangeOfString:@"引用"].length != 0) {
        fragment.children = [self fragmentsFromTree:content.children];
        fragment.isBlock = YES;
        return fragment;
    } else if ([typeString rangeOfString:@"代码"].length != 0) {
        return [self fragmentFromCode:content];
    } else {
        // unknown center block
        NSLog(@"unknown center block:%@", center.raw);
        return nil;
    }
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
    
    fragment.isBlock = YES;
    BUCPostFragment *child = [[BUCPostFragment alloc] init];
    child.richText = richText;
    child.isRichText = YES;
    fragment.children = [NSArray arrayWithObjects:child, nil];
    
    return fragment;
}


- (BUCPostFragment *)fragmentFromBox:(TFHppleElement *)box {
    NSString *query = @"//blockquote/div";
    NSArray *nodes = [box searchWithXPathQuery:query];
    BUCPostFragment *fragment = [[BUCPostFragment alloc] init];
    fragment.isBlock = YES;
    fragment.children = [self fragmentsFromTree:[[nodes lastObject] children]];
    
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
    fragment.isBlock = YES;
    fragment.richText = richText;
    
    return fragment;
}


#pragma mark - inline element
- (NSMutableAttributedString *)richTextFromText:(TFHppleElement *)text {
    // strike and video tag needed to be suppported
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:[self replaceHtmlEntities:text.content] attributes:[self attributesForFontStyle:UIFontTextStyleBody]];
    
    return output;
}


- (BUCImage *)imageFromImageNode:(TFHppleElement *)imageNode {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\.\\./images/.+$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *imageSrc = [imageNode objectForKey:@"src"];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:imageSrc options:0 range:(NSRange){0, imageSrc.length}];
    BUCImage *image = [[BUCImage alloc] init];

    if (numberOfMatches == 1) {
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        NSData *imageData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", resourcePath, [imageSrc substringFromIndex:3]]];
        image.image = [UIImage animatedImageWithAnimatedGIFData:imageData];
        image.bounds = (CGRect){(CGPoint){0, 0}, image.image.size};
    } else {
        image.url = [NSURL URLWithString:imageSrc];
        image.bounds = CGRectMake(0, 0, 150.0f, 200.0f);
        if ([image.url.pathExtension isEqualToString:@"gif"]) {
            image.isGif = YES;
        } else {
            image.isGif = NO;
        }
    }
    
    return image;
}


- (NSAttributedString *)richTextFromSpan:(TFHppleElement *)span {
    if ([[span objectForKey:@"id"] isEqualToString:@"id_open_api_label"]) {
        NSString *url = @"http://out.bitunion.org/thread-10471436-1-1.html";
        NSDictionary *attributes = [self attributesForFontStyle:UIFontTextStyleBody];
        NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@"\n\n..::" attributes:attributes];
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


- (NSDictionary *)attributesFromFont:(TFHppleElement *)font {
    NSDictionary *colorAttribute;
    
    // ignore custom size text, only process colored text
    NSString *colorString = [font objectForKey:@"color"];
    if (colorString) {
        UIColor *color = [self parseColorAttr:colorString];
        colorAttribute = @{NSForegroundColorAttributeName:color};
    }
    
    return colorAttribute;
}


- (NSDictionary *)attributesFromA:(TFHppleElement *)a {
    NSString *linkAttributeKey;
    NSString *linkAttributeValue;
    
    NSRegularExpression *summonRegex = [self regexFromPattern:@"^/profile-username-.+\\.html$"];
    NSRegularExpression *mailRegex = [self regexFromPattern:@"^mailto:.+$"];
    NSString *href = [a objectForKey:@"href"];
    
    if (!href) {
        return nil;
    }
    
    if ([self matchString:href withRegex:summonRegex]) {
        linkAttributeKey = @"BUCSummonLink";
        linkAttributeValue = a.firstChild.content;
    } else if ([self matchString:href withRegex:mailRegex]) {
        linkAttributeKey = @"BUCMailLink";
        linkAttributeValue = [href substringFromIndex:7];
    } else {
        linkAttributeKey = NSLinkAttributeName;
        linkAttributeValue = href;
    }
    
    NSDictionary *linkAttribute = @{linkAttributeKey:linkAttributeValue};
    
    return linkAttribute;
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
    
    NSRegularExpression *regex = [self regexFromPattern:@"^#([a-z0-9]{3}|[a-z0-9]{6})$"];
    NSUInteger numberOfMatches = [self matchString:colorString withRegex:regex];
    
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


- (UIFont *)fontForFontStyle:(NSString *)style trait:(uint32_t)trait {
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
    
    UIFontDescriptor *descriptorWithTrait = [fontDescriptor fontDescriptorWithSymbolicTraits:trait];
    
    return [UIFont fontWithDescriptor:descriptorWithTrait size: 0.0];
}


- (NSMutableDictionary *)attributesForFontStyle:(NSString *)style {
    return [[NSMutableDictionary alloc] initWithObjectsAndKeys:[UIFont preferredFontForTextStyle:style], NSFontAttributeName, nil];
}


- (BOOL)isBlockElement:(TFHppleElement *)e {
    NSString *tagName = e.tagName;
    if ([tagName isEqualToString:@"center"] ||
        [tagName isEqualToString:@"blockquote"] ||
        [tagName isEqualToString:@"ol"] ||
        [tagName isEqualToString:@"ul"]) {
        
        return YES;
    } else {
        return NO;
    }
}


- (BOOL)matchString:(NSString *)string withRegex:(NSRegularExpression *)regex
{
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:string options:0 range:(NSRange){0, string.length}];
    
    if (numberOfMatches > 0) {
        return YES;
    } else {
        return NO;
    }
}


- (NSRegularExpression *)regexFromPattern:(NSString *)pattern
{
    NSError *error;
    
    return [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
}


- (void)addAttributes:(NSDictionary *)attributes toRichText:(NSMutableAttributedString *)richText
{
    [richText enumerateAttributesInRange:(NSRange){0, richText.length}
                                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                              usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
                                  for (NSString *key in attributes) {
                                      if ([key isEqualToString:NSFontAttributeName] || ![attrs objectForKey:key]) {
                                          [richText addAttribute:key value:[attributes objectForKey:key] range:range];
                                      }
                                  }
                              }];
}


@end


















