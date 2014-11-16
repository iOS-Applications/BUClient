#import "BUCHTMLScraper.h"
#import "TFHpple.h"
#import "UIImage+animatedGIF.h"
#import "BUCConstants.h"
#import "BUCModels.h"




@implementation BUCHTMLScraper


#pragma mark - public interface
- (NSAttributedString *)titleFromHTML:(NSString *)html{
    BUCRenderNode *title = [[self fragmentsFromHTML:html] lastObject];
    
    return title.richText;
}


- (NSArray *)fragmentsFromHTML:(NSString *)html {
    return [self fragmentsFromTree:[self treeFromHTML:html]];
}


- (NSAttributedString *)richTextFromHtml:(NSString *)html {
    return [self richTextFromTree:[self treeFromHtml:html]];
}


- (TFHppleElement *)treeFromHtml:(NSString *)html {
    return  nil;
}


- (NSURL *)avatarUrlFromHtml:(NSString *)html
{
    if (!html || html.length == 0) {
        return nil;
    }
    
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    NSString *query = @"//body";
    NSArray *nodes = [[[parser searchWithXPathQuery:query] firstObject] children];
    
    NSString *urlString = [[nodes firstObject] objectForKey:@"src"];
    NSString *buBaseUrl = @"http://out.bitunion.org";
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSRegularExpression *lanRegex = [self regexFromPattern:@"^http://www\\.bitunion\\.org/.+$"];
    NSRegularExpression *relativeRegex = [self regexFromPattern:@"^images/.+$"];
    NSRegularExpression *attachmentRegex = [self regexFromPattern:@"^/attachments/.+$"];
    
    if ([url.host isEqualToString:@"bitunion.org"]) {
        urlString = [NSString stringWithFormat:@"%@%@", buBaseUrl, url.path];
    } else if ([self matchString:urlString withRegex:lanRegex]) {
        urlString = [urlString stringByReplacingOccurrencesOfString:@"www.bitunion.org" withString:@"out.bitunion.org"];
    } else if ([self matchString:urlString withRegex:relativeRegex]) {
        urlString = [NSString stringWithFormat:@"%@/%@", @"http://out.bitunion.org", urlString];
    } else if ([self matchString:urlString withRegex:attachmentRegex]) {
        urlString = [NSString stringWithFormat:@"%@%@", @"http://out.bitunion.org", urlString];
    }
    
    return [NSURL URLWithString:urlString];
}


#pragma mark - top level tree
- (NSArray *)treeFromHTML:(NSString *)html {
    if (html.length == 0) {
        return nil;
    }

    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    NSString *query = @"//body";
    NSArray *nodes = [[[parser searchWithXPathQuery:query] firstObject] children];
    
    if (nodes.count == 0) {
        return nil;
    }
    
    return nodes;
}


- (NSArray *)fragmentsFromTree:(NSArray *)tree {
    if (!tree) {
        return nil;
    }
    
    NSMutableArray *fragments = [[NSMutableArray alloc] init];
    BUCRenderNode *lastFragment;
    
    for (TFHppleElement *node in tree) {
        BUCRenderNode *fragment;
        NSString *tagName = node.tagName;
        
        if ([tagName isEqualToString:@"br"]) {
            continue;
        } else if ([tagName isEqualToString:@"p"]) {
            fragment = [self fragmentFromP:node];
            
        } else if ([node isTextNode] ||
                   [tagName isEqualToString:@"span"] ||
                   [tagName isEqualToString:@"font"] ||
                   [tagName isEqualToString:@"b"] ||
                   [tagName isEqualToString:@"i"] ||
                   [tagName isEqualToString:@"u"]) {
            
            NSMutableAttributedString *richText = [self richTextFromTree:node];
            
            if (!richText) {
                continue;
            }
            
            if (lastFragment.isRichText) {
                [lastFragment.richText appendAttributedString:richText];
                continue;
            } else {
                fragment = [[BUCRenderNode alloc] initWithRichText:richText];
            }
            
        } else if ([tagName isEqualToString:@"a"]) {
            
            NSMutableAttributedString *richText = [self richTextFromTree:node];
            if (!richText) {
                continue;
            }
            
            BUCLinkAttribute *linkAttribute = [richText attribute:BUCLinkAttributeName atIndex:0 effectiveRange:NULL];
            if (lastFragment.isRichText) {
                [lastFragment.richText appendAttributedString:richText];
                linkAttribute.range = NSMakeRange(lastFragment.richText.length, richText.length);
                continue;
            } else {
                fragment = [[BUCRenderNode alloc] initWithRichText:richText];
                linkAttribute.range = NSMakeRange(0, richText.length);
            }
            
        } else if ([tagName isEqualToString:@"img"]) {
            BUCImageAttachment *image = [self imageFromImageNode:node];
            
            if (!image) {
                continue;
            }
            
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.bounds = image.bounds;
            NSMutableAttributedString *richText = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString  attributedStringWithAttachment:attachment]];
            if (lastFragment.isRichText) {
                image.glyphIndex = lastFragment.richText.length;
                [lastFragment.richText appendAttributedString:richText];
                [lastFragment addAttachment:image];
                continue;
            } else {                
                fragment = [[BUCRenderNode alloc] initWithRichText:richText];
                image.glyphIndex = 0;
                [fragment addAttachment:image];
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
    NSMutableAttributedString *output;
    NSDictionary *attributes;
    NSString *tagName = tree.tagName;
    
    if ([tree isTextNode] == YES) {
        return [self richTextFromText:tree parent:nil];
    } else if ([tagName isEqualToString:@"a"]) {
        attributes = [self attributeFromA:tree];
    } else if ([tagName isEqualToString:@"font"]) {
        attributes = [self attributesFromFont:tree];
    } else if ([tagName isEqualToString:@"b"]) {
        attributes = [self attributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitBold];
    } else if ([tagName isEqualToString:@"i"]) {
        attributes = [self attributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitItalic];
    } else if ([tagName isEqualToString:@"u"]) {
        attributes = @{NSUnderlineStyleAttributeName:@1};
    } else if ([tagName isEqualToString:@"span"]) {
        return [self richTextFromSpan:tree parent:nil];
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


- (BUCRenderNode *)rootRenderNode:(TFHppleElement *)bodyElement {
    if (!bodyElement) {
        return nil;
    }
    
    BUCRenderNode *body = [[BUCRenderNode alloc] init];
    body.attributes = [self attributesForFontStyle:UIFontTextStyleBody];
    
    for (TFHppleElement *child in body.children) {
        if ([child.tagName isEqualToString:@"br"]) {
            continue;
        } else {
            [body addChildNode:[self renderNode:child parent:body]];
        }
    }
//    if ([body isTextNode] == YES) {
//        renderNode = [self textNode:body];
//    } else if ([tagName isEqualToString:@"img"]) {
//        renderNode = [self imageNode:body];
//    } else if ([tagName isEqualToString:@"a"]) {
//        renderNode = [self linkNode:body parent:parent];
//    } else if ([tagName isEqualToString:@"font"]) {
//        attributes = [self attributesFromFont:body];
//    } else if ([tagName isEqualToString:@"b"]) {
//        attributes = [self attributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitBold];
//    } else if ([tagName isEqualToString:@"i"]) {
//        attributes = [self attributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitItalic];
//    } else if ([tagName isEqualToString:@"u"]) {
//        attributes = @{NSUnderlineStyleAttributeName:@1};
//    } else if ([tagName isEqualToString:@"span"]) {
//        richText = [self richTextFromSpan:body parent:parent];
//    } else if ([tagName isEqualToString:@"center"]) {
//        
//    } else if ([tagName isEqualToString:@"blockquote"]) {
//        
//    } else if ([tagName isEqualToString:@"ol"] || [tagName isEqualToString:@"url"]) {
//        
//    } else {
//        NSLog(@"unknown inline element type:%@", tagName);
//    }
    
    return body;
}


- (BUCRenderNode *)renderNode:(TFHppleElement *)htmlElement parent:(BUCRenderNode *)parent {
    
    return nil;
}


- (BUCRenderNode *)textNode:(TFHppleElement *)htmlElement {
    // strike and video support are needed
    NSString *content = htmlElement.content;
    if (content && content.length > 0) {
        return [[BUCRenderNode alloc] initWithString:content];
    } else {
        return nil;
    }
}


- (BUCRenderNode *)imageNode:(TFHppleElement *)htmlElement {
    NSString *src = [htmlElement objectForKey:@"src"];
    if (!src || src.length == 0) {
        return nil;
    }
    
    BUCImageAttachment *attachment = [[BUCImageAttachment alloc] init];
    attachment.glyphIndex = 0;
    NSRegularExpression *regex = [self regexFromPattern:@"^\\.\\./images/.+$"];
    
    if ([self matchString:src withRegex:regex]) {
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        NSString *path = [NSString stringWithFormat:@"%@/%@", resourcePath, [src substringFromIndex:3]];
        UIImage *image = [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfFile:path]];
        attachment.image = image;
        attachment.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
    } else {
        attachment.url = [NSURL URLWithString:src];
        attachment.bounds = CGRectMake(0, 0, BUCImageThumbnailWidth, BUCImageThumbnailHeight);
    }
    
    return [[BUCRenderNode alloc] initWithAttachment:attachment];
}


- (BUCRenderNode *)linkNode:(TFHppleElement *)htmlElement parent:(BUCRenderNode *)parent {
    BUCRenderNode *node = [[BUCRenderNode alloc] init];
    node.attributes = [self linkAttribute:htmlElement];
    
    for (TFHppleElement *child in htmlElement.children) {
        BUCRenderNode *childNode = [self rootRenderNode:child parent:node];
        
        if (node.lastChild) {
            
            if (!node.lastChild.isBlock && !childNode.isBlock) {

                if (childNode.attachmentList) {
                    
                }
                [node.lastChild.richText appendAttributedString:childNode.richText];
            }
            
        } else {
            
        }
    }
    
    return node;
}


- (NSDictionary *)linkAttribute:(TFHppleElement *)htmlElement {
    NSString *href = [htmlElement objectForKey:@"href"];
    if (!href) {
        return nil;
    }
    
    NSRegularExpression *usernameRegex = [self regexFromPattern:@"^/profile-username-.+\\.html$"];
    NSRegularExpression *mailRegex = [self regexFromPattern:@"^mailto:.+$"];
    NSRegularExpression *buRegex  = [self regexFromPattern:@"^(http://)?(((www)|(out)|(us))\\.)?bitunion\\.org(/.*)?$"];
    NSRegularExpression *threadRegex = [self regexFromPattern:@"^/thread-([1-9][0-9]+)-[1-9]-[1-9].html$"];
    NSRegularExpression *forumRegex = [self regexFromPattern:@"^/forum-([1-9]{1,3})-[1-9].html$"];
    NSString *buDomanName = @"bitunion.org";
    
    BUCLinkAttribute *linkAttribute = [[BUCLinkAttribute alloc] init];
    UIColor *linkColor;
    
    if ([self matchString:href withRegex:usernameRegex]) {
        linkAttribute.linkType = BUCUserLink;
        linkAttribute.linkUrl = htmlElement.firstChild.content;
        linkColor = [self parseColorAttr:@"summon"];
    } else if ([self matchString:href withRegex:buRegex]) {
        linkColor = [self parseColorAttr:@"url"];
        NSRange hostRange = [href rangeOfString:buDomanName];
        NSUInteger pathIndex = hostRange.location + hostRange.length;
        NSString *path;
        if (pathIndex < href.length) {
            path = [href substringFromIndex:pathIndex];
        }
        
        if (!path || [path isEqualToString:@"/"] || [path isEqualToString:@"/home.php"]) {
            linkAttribute.linkType = BUCHomeLink;
        } else if ([path isEqualToString:@"/index.php"]) {
            linkAttribute.linkType = BUCForumListLink;
        } else if ([self matchString:path withRegex:threadRegex]) {
            NSArray *matches = [threadRegex matchesInString:path options:0 range:NSMakeRange(0, path.length)];
            NSTextCheckingResult *match = [matches lastObject];
            linkAttribute.linkType = BUCPostLink;
            linkAttribute.linkUrl = [path substringWithRange:match.range];
        } else if ([self matchString:path withRegex:forumRegex]) {
            NSArray *matches = [forumRegex matchesInString:path options:0 range:NSMakeRange(0, path.length)];
            NSTextCheckingResult *match = [matches lastObject];
            linkAttribute.linkType = BUCForumLink;
            linkAttribute.linkUrl = [path substringWithRange:match.range];
        } else {
            linkAttribute.linkType = BUCUrlLink;
            linkAttribute.linkUrl = href;
        }
    } else if ([self matchString:href withRegex:mailRegex]) {
        linkAttribute.linkType = BUCMailLink;
        linkAttribute.linkUrl = [href substringFromIndex:7];
        linkColor = [self parseColorAttr:@"mail"];
    } else {
        linkAttribute.linkType = BUCUrlLink;
        linkAttribute.linkUrl = href;
        linkColor = [self parseColorAttr:@"url"];
    }
    
    return @{BUCLinkAttributeName:linkAttribute, NSForegroundColorAttributeName:linkColor};
}


#pragma mark - block element
- (BUCRenderNode *)fragmentFromP:(TFHppleElement *)p {
    BUCRenderNode *fragment = [[BUCRenderNode alloc] init];
    fragment.isRichText = YES;
    fragment.richText = [[NSMutableAttributedString alloc] initWithString:@""];
    
    for (TFHppleElement *node in p.children) {
        if ([node.tagName isEqualToString:@"br"]) {
            continue;
        } else if ([node.tagName isEqualToString:@"img"]) {
            BUCImageAttachment *image = [self imageFromImageNode:node];
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.bounds = image.bounds;
            NSAttributedString *richText = [NSAttributedString attributedStringWithAttachment:attachment];
            image.glyphIndex = fragment.richText.length;
            [fragment.richText appendAttributedString:richText];
            [fragment addAttachment:image];
        } else {
            NSAttributedString *richText = [self richTextFromTree:node];
            if (!richText) {
                continue;
            }
            [fragment.richText appendAttributedString:richText];
        }
    }
    
    return fragment;
}


- (BUCRenderNode *)fragmentFromCenter:(TFHppleElement *)center {
    NSString *query = @"//center/table/tr/td";
    NSArray *nodes = [center searchWithXPathQuery:query];
    NSString *typeString = [[[nodes firstObject] firstChild] content];
    query = @"//table/tr/td/table/tr/td";
    nodes = [center searchWithXPathQuery:query];
    TFHppleElement *content = [nodes firstObject];
    BUCRenderNode *fragment = [[BUCRenderNode alloc] init];

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


- (BUCRenderNode *)fragmentFromCode:(TFHppleElement *)codeBlock {
    NSString *query = @"//div/ol/li";
    NSArray *codeLines = [codeBlock searchWithXPathQuery:query];
    
    BUCRenderNode *fragment = [[BUCRenderNode alloc] init];
    NSDictionary *attrs = [self attributesForFontStyle:UIFontTextStyleBody];
    NSMutableAttributedString *richText = [[NSMutableAttributedString alloc] initWithString:@""];
    
    for (TFHppleElement *line in codeLines) {
        NSString *buffer = [NSString stringWithFormat:@"%@\n", line.firstChild.content];
        [richText appendAttributedString:[[NSAttributedString alloc] initWithString:buffer attributes:attrs]];
    }
    
    fragment.isBlock = YES;
    BUCRenderNode *child = [[BUCRenderNode alloc] init];
    child.richText = richText;
    child.isRichText = YES;
    fragment.children = [NSArray arrayWithObjects:child, nil];
    
    return fragment;
}


- (BUCRenderNode *)fragmentFromBox:(TFHppleElement *)box {
    NSString *query = @"//blockquote/div";
    NSArray *nodes = [box searchWithXPathQuery:query];
    // background color support needed
    BUCRenderNode *fragment = [[BUCRenderNode alloc] init];
    fragment.isBlock = YES;
    fragment.children = [self fragmentsFromTree:[[nodes lastObject] children]];
    
    return fragment;
}


- (BUCRenderNode *)fragmentFromList:(TFHppleElement *)list {
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
    
    BUCRenderNode *fragment = [[BUCRenderNode alloc] init];
    fragment.isBlock = YES;
    fragment.richText = richText;
    
    return fragment;
}


#pragma mark - inline element
- (NSMutableAttributedString *)richTextFromText:(TFHppleElement *)text parent:(BUCRenderNode *)parent {
    // strike and video tag needed to be suppported
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:[self replaceHtmlEntities:text.content] attributes:[self attributesForFontStyle:UIFontTextStyleBody]];
    
    return output;
}


- (BUCImageAttachment *)imageFromImageNode:(TFHppleElement *)imageNode {
    NSRegularExpression *regex = [self regexFromPattern:@"^\\.\\./images/.+$"];
    NSString *imageSrc = [imageNode objectForKey:@"src"];
    NSURL *url = [NSURL URLWithString:imageSrc];
    BUCImageAttachment *image = [[BUCImageAttachment alloc] init];

    if ([self matchString:imageSrc withRegex:regex]) {
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        NSData *imageData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", resourcePath, [imageSrc substringFromIndex:3]]];
        image.image = [UIImage animatedImageWithAnimatedGIFData:imageData];
        image.bounds = (CGRect){(CGPoint){0, 0}, image.image.size};
    } else {
        image.url = [NSURL URLWithString:imageSrc];
        image.bounds = CGRectMake(0, 0, BUCImageThumbnailWidth, BUCImageThumbnailHeight);
    }
    
    return image;
}


- (NSMutableAttributedString *)richTextFromSpan:(TFHppleElement *)span parent:(BUCRenderNode *)parent {
    if (![[span objectForKey:@"id"] isEqualToString:@"id_open_api_label"]) {
        NSLog(@"unknown span tag:%@", span.raw);
        return nil;
    }
    
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:@"北理FTP联盟API"];
    [output addAttribute:NSForegroundColorAttributeName value:[self parseColorAttr:@"buUrl"] range:NSMakeRange(0, output.length)];

    BUCLinkAttribute *linkAttribute = [[BUCLinkAttribute alloc] init];
    linkAttribute.linkType = BUCPostLink;
    linkAttribute.linkUrl = @"10471436"; // 联盟API帖子的tid
    [output addAttribute:BUCLinkAttributeName value:linkAttribute range:NSMakeRange(0, output.length)];

    return output;
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


- (NSDictionary *)attributeFromA:(TFHppleElement *)a {
    NSString *href = [a objectForKey:@"href"];
    if (!href) {
        return nil;
    }
    
    NSRegularExpression *summonRegex = [self regexFromPattern:@"^/profile-username-.+\\.html$"];
    NSRegularExpression *mailRegex = [self regexFromPattern:@"^mailto:.+$"];

    
    BUCLinkAttribute *linkAttribute = [[BUCLinkAttribute alloc] init];
    UIColor *linkColor;
    
    if ([self matchString:href withRegex:summonRegex]) {
        linkAttribute.linkType = BUCUserLink;
        linkAttribute.linkUrl = a.firstChild.content;
        linkColor = [self parseColorAttr:@"summon"];
    } else if ([self matchString:href withRegex:mailRegex]) {
        linkAttribute.linkType = BUCMailLink;
        linkAttribute.linkUrl = [href substringFromIndex:7];
        linkColor = [self parseColorAttr:@"mail"];
    } else {
        linkAttribute.linkType = BUCUrlLink;
        linkAttribute.linkUrl = href;
        linkColor = [self parseColorAttr:@"url"];
    }
    
    return @{BUCLinkAttributeName:linkAttribute, NSForegroundColorAttributeName:linkColor};
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
                       @"#cc3333":    [UIColor colorWithRed:204.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1.0f],
                       @"summon":     [UIColor colorWithRed:0 green:102.0f/255.0f blue:153.0f/255.0f alpha:1.0f],
                       @"mail":       [UIColor colorWithRed:0 green:128.0f/255.0f blue:1.0f alpha:1.0f],
                       @"url":        [UIColor colorWithRed:0 green:122.0f/255.0f blue:1.0f alpha:1.0f]
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
    return [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
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


















