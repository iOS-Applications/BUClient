#import "BUCHTMLScraper.h"
#import "TFHpple.h"
#import "UIImage+animatedGIF.h"
#import "BUCConstants.h"
#import "BUCModels.h"


@interface BUCHTMLScraper ()

@property (nonatomic) NSMutableAttributedString *output;
@property (nonatomic) NSMutableArray *attachmentList;
@property (nonatomic) NSMutableArray *blockList;

@end


@implementation BUCHTMLScraper


#pragma mark - public interface
- (NSURL *)avatarUrlFromHtml:(NSString *)html {
    if (!html || html.length == 0) {
        return nil;
    }
    
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    NSString *query = @"//body";
    NSArray *nodes = [[[parser searchWithXPathQuery:query] firstObject] children];
    
    NSString *source = [[nodes firstObject] objectForKey:@"src"];
    return [self parseImageUrl:source];
}


- (NSAttributedString *)richTextFromHtml:(NSString *)html { 
    return [self richTextFromTree:[self treeFromHtml:html]];
}


#pragma mark - top level
- (TFHppleElement *)treeFromHtml:(NSString *)html {
    if (!html || html.length == 0) {
        return nil;
    }
    
    TFHpple *parser = [TFHpple hppleWithHTMLData:[html dataUsingEncoding:NSUTF8StringEncoding]];
    TFHppleElement *body = [[parser searchWithXPathQuery:@"//body"] firstObject];
    
    if (!body || !body.children || body.children.count == 0) {
        return nil;
    }
    
    return body;
}


- (NSAttributedString *)richTextFromTree:(TFHppleElement *)tree {
    if (!tree) {
        return nil;
    }
    
    NSDictionary *baseAttribute = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
    self.output = [[NSMutableAttributedString alloc] init];
    self.attachmentList = [[NSMutableArray alloc] init];
    self.blockList = [[NSMutableArray alloc] init];
    
    for (TFHppleElement *node in tree.children) {
        if ([node.tagName isEqualToString:@"br"]) {
            continue;
        }
        
        [self appendRichText:node superAttributes:baseAttribute];
    }
    
    if (self.output.length == 0) {
        return nil;
    }
    
    if (self.attachmentList.count > 0) {
        [self.output addAttribute:BUCAttachmentListAttributeName value:self.attachmentList range:NSMakeRange(0, 1)];
    }
    
    if (self.blockList.count > 0) {
        [self.output addAttribute:BUCTextBlockListAttributeName value:self.blockList range:NSMakeRange(0, 1)];
    }
    
    return self.output;
}


- (void)appendRichText:(TFHppleElement *)tree superAttributes:(NSDictionary *)superAttributes {
    NSString *tagName = tree.tagName;
    
    if ([tree isTextNode]) {
        [self appendText:tree superAttributes:superAttributes];
    } else if ([tagName isEqualToString:@"img"]) {
        [self appendImage:tree superAttributes:superAttributes];
    } else if ([tagName isEqualToString:@"center"] || [tagName isEqualToString:@"blockquote"] ||
               [tagName isEqualToString:@"ul"] || [tagName isEqualToString:@"ol"]) {
        
        NSMutableDictionary *thisAttributes = [NSMutableDictionary dictionaryWithDictionary:superAttributes];
        BUCTextBlockAttribute *blockAttribute = [self setUpBlockAttribute:thisAttributes];
        [thisAttributes setObject:blockAttribute forKey:BUCTextBlockAttributeName];
        [self beginBlock:superAttributes];
        [self insertNewLine:superAttributes];
        NSUInteger location = self.output.length;
        
        if ([tagName isEqualToString:@"center"]) {
            [self appendCenter:tree superAttributes:thisAttributes];
        } else if ([tagName isEqualToString:@"blockquote"]) {
            NSString *query = @"//blockquote/div";
            NSArray *nodes = [tree searchWithXPathQuery:query];
            TFHppleElement *box = [nodes lastObject];
            blockAttribute.backgroundColor = [self parseBoxColor:box];
            [self appendBox:box superAttributes:thisAttributes];
        } else {
            [self appendList:tree superAttributes:thisAttributes];
        }
        
        [self finishBlock:thisAttributes];
        NSUInteger length = self.output.length - location;
        blockAttribute.range = NSMakeRange(location, length);
        [self.blockList addObject:blockAttribute];
        [self insertNewLine:superAttributes];
    } else {
        NSDictionary *attributes;
        NSMutableDictionary *thisAttributes = [NSMutableDictionary dictionaryWithDictionary:superAttributes];
        NSUInteger location = self.output.length;
        
        if ([tagName isEqualToString:@"p"]) {
            // do nothing
        } else if([tagName isEqualToString:@"span"] && [[tree objectForKey:@"id"] isEqualToString:@"id_open_api_label"]) {
            [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n" attributes:superAttributes]];
            [thisAttributes setObject:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] forKey:NSFontAttributeName];
        } else if ([tagName isEqualToString:@"a"]) {
            attributes = [self linkAttributes:tree];
        } else if ([tagName isEqualToString:@"font"]) {
            attributes = [self fontAttributes:tree];
        } else if ([tagName isEqualToString:@"b"]) {
            attributes = [self attributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitBold];
        } else if ([tagName isEqualToString:@"i"]) {
            attributes = [self attributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitItalic];
        } else if ([tagName isEqualToString:@"u"]) {
            attributes = @{NSUnderlineStyleAttributeName:@1};
        } else {
            NSLog(@"unknown tag type:%@", tagName);
            return;
        }
        
        for (NSString *key in attributes) {
            [thisAttributes setObject:[attributes objectForKey:key] forKey:key];
        }
        
        for (TFHppleElement *node in tree.children) {
            if ([node.tagName isEqualToString:@"br"]) {
                continue;
            }
            
            [self appendRichText:node superAttributes:thisAttributes];
        }


        if ([tagName isEqualToString:@"a"]) {
            NSUInteger length = self.output.length - location;
            BUCLinkAttribute *linkAttribute = [thisAttributes objectForKey:BUCLinkAttributeName];
            linkAttribute.range = NSMakeRange(location, length);
        }
    }
}


#pragma mark - inline elements
- (void)appendText:(TFHppleElement *)tree superAttributes:(NSDictionary *)superAttributes {
    // strike and video support are needed...
    if (!tree.content || tree.content.length == 0) {
        return;
    }
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:superAttributes];
    NSRegularExpression *regex = [self regexFromPattern:@"\\s*\\[ Last edited by .+ on [0-9]{4}-[0-9]{1,2}-[0-9]{1,2} at [0-9]{2}:[0-9]{2} \\]"];
    if ([self matchString:tree.content withRegex:regex]) {
        [attributes setObject:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] forKeyedSubscript:NSFontAttributeName];
    }
    
    [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:[self replaceHtmlEntities:tree.content] attributes:attributes]];
}


- (void)appendImage:(TFHppleElement *)tree superAttributes:(NSDictionary *)superAttributes {
    NSString *source = [tree objectForKey:@"src"];
    if (!source || source.length == 0) {
        return;
    }

    BUCImageAttachment *attachment = [[BUCImageAttachment alloc] init];
    NSRegularExpression *regex = [self regexFromPattern:@"^\\.\\./images/.+$"];
    
    if ([self matchString:source withRegex:regex]) {
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        NSString *path = [NSString stringWithFormat:@"%@/%@", resourcePath, [source substringFromIndex:3]];
        UIImage *image = [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfFile:path]];
        if (!image) {
            return;
        } else {
            attachment.gif = image;
            attachment.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
        }
    } else {
        attachment.url = [self parseImageUrl:source];
        if (!attachment.url) {
            return;
        } else {
            attachment.bounds = CGRectMake(0, 0, BUCImageThumbnailWidth, BUCImageThumbnailHeight);
        }
    }
    
    attachment.glyphIndex = [self.output length];
    [self.attachmentList addObject:attachment];
    
    [self.output appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
}


#pragma mark - block elements
- (void)appendCenter:(TFHppleElement *)tree superAttributes:(NSDictionary *)superAttributes {
    NSString *query = @"//center/table/tr/td";
    NSArray *nodes = [tree searchWithXPathQuery:query];
    NSString *typeString = [[[nodes firstObject] firstChild] content];
    query = @"//table/tr/td/table/tr/td";
    nodes = [tree searchWithXPathQuery:query];
    TFHppleElement *content = [nodes firstObject];
    
    if ([typeString rangeOfString:@"引用"].length > 0) {
        [self appendQuote:content superAttributes:superAttributes];
    } else if ([typeString rangeOfString:@"代码"].length > 0) {
        [self appendCode:content superAttributes:superAttributes];
    } else {
        NSLog(@"unknown center block:%@", tree.raw);
    }
}


- (void)appendQuote:(TFHppleElement *)tree superAttributes:(NSDictionary *)superAttributes {
    if (!tree || !tree.children || tree.children.count == 0) {
        return;
    }
    
    for (TFHppleElement *node in tree.children) {
        if ([node.tagName isEqualToString:@"br"]) {
            continue;
        }
        
        [self appendRichText:node superAttributes:superAttributes];
    }
}


- (void)appendBox:(TFHppleElement *)tree superAttributes:(NSDictionary *)superAttributes {
    for (TFHppleElement *node in tree.children) {
        if ([node.tagName isEqualToString:@"br"]) {
            continue;
        }
        
        [self appendRichText:node superAttributes:superAttributes];
    }
}


- (void)appendCode:(TFHppleElement *)tree superAttributes:(NSDictionary *)superAttributes {
    NSString *query = @"//div/ol/li";
    NSArray *codeLines = [tree searchWithXPathQuery:query];
    
    if (!codeLines || codeLines.count == 0) {
        return;
    }
    
    for (TFHppleElement *line in codeLines) {
        if (!line.firstChild.content) {
            continue;
        }
        
        NSString *buffer = [NSString stringWithFormat:@"%@\n", line.firstChild.content];
        [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:buffer attributes:superAttributes]];
    }
}


- (void)appendList:(TFHppleElement *)tree superAttributes:(NSDictionary *)superAttributes {
    NSString *query = @"//li";
    NSArray *nodes = [tree searchWithXPathQuery:query];
    
    for (TFHppleElement *node in nodes) {
        if ([node.tagName isEqualToString:@"br"]) {
            continue;
        } else if ([node.firstChild isTextNode] && node.firstChild.content) {
            NSString *buffer = [NSString stringWithFormat:@"• %@\n", node.firstChild.content];
            [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:buffer attributes:superAttributes]];
        } else {
            [self appendRichText:node superAttributes:superAttributes];
        }
    }
}


#pragma mark - attributes parsing
- (NSDictionary *)fontAttributes:(TFHppleElement *)font {
    NSMutableDictionary *fontAttributes = [[NSMutableDictionary alloc] init];
    
    // size attribute support is needed..
    NSString *color = [font objectForKey:@"color"];
    if (color) {
        [fontAttributes setObject:[self colorAttribute:color] forKey:NSForegroundColorAttributeName];
    }
    
    NSString *size = [font objectForKey:@"size"];
    
    if (size && size.length > 0) {
        [fontAttributes setObject:[self fontWithSize:size] forKey:NSFontAttributeName];
    }
    
    return fontAttributes;
}


- (UIFont *)fontWithSize:(NSString *)size {
    int sizeNumber = size.intValue;
    CGFloat fontSize;
    if (sizeNumber < 0) {
        fontSize = 11.0f;
    } else if (sizeNumber <= 3) {
        fontSize = 17.0f;
    } else if (sizeNumber <= 6) {
        fontSize = 24.0f;
    } else {
        fontSize = 36.0f;
    }
    
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    
    UIFontDescriptor *descriptorWithSize = [fontDescriptor fontDescriptorWithSize:fontSize];
    
    UIFont *font = [UIFont fontWithDescriptor:descriptorWithSize size: fontSize];
    
    return font;
}


- (UIColor *)colorAttribute:(NSString *)color {
    static NSDictionary* colorTable;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorTable = @{
                       @"white":      [UIColor whiteColor],
                       @"black":      [UIColor blackColor],
                       @"red":        [UIColor redColor],
                       @"green":      [UIColor colorWithRed:0 green:128.0f/255.0f blue:0 alpha:1.0f],
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
    
    UIColor *output = [colorTable objectForKey:[color lowercaseString]];
    
    if (output) {
        return output;
    }
    
    NSRegularExpression *regex = [self regexFromPattern:@"^#\\s*([a-z0-9]{3}|[a-z0-9]{6})$"];
    NSUInteger numberOfMatches = [self matchString:color withRegex:regex];
    
    if (numberOfMatches == 0) {
        output = [UIColor blackColor];
    } else {
        NSString *cleanString = [color stringByReplacingOccurrencesOfString:@"#" withString:@""];
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


- (NSDictionary *)linkAttributes:(TFHppleElement *)htmlElement {
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
        linkColor = [self colorAttribute:@"summon"];
    } else if ([self matchString:href withRegex:buRegex]) {
        linkColor = [self colorAttribute:@"url"];
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
            linkAttribute.linkUrl = [path substringWithRange:[match rangeAtIndex:1]];
        } else if ([self matchString:path withRegex:forumRegex]) {
            NSArray *matches = [forumRegex matchesInString:path options:0 range:NSMakeRange(0, path.length)];
            NSTextCheckingResult *match = [matches lastObject];
            linkAttribute.linkType = BUCForumLink;
            linkAttribute.linkUrl = [path substringWithRange:[match rangeAtIndex:1]];
        } else {
            linkAttribute.linkType = BUCUrlLink;
            linkAttribute.linkUrl = href;
        }
    } else if ([self matchString:href withRegex:mailRegex]) {
        linkAttribute.linkType = BUCMailLink;
        linkAttribute.linkUrl = [href substringFromIndex:7];
        linkColor = [self colorAttribute:@"mail"];
    } else {
        linkAttribute.linkType = BUCUrlLink;
        linkAttribute.linkUrl = href;
        linkColor = [self colorAttribute:@"url"];
    }
    
    return @{BUCLinkAttributeName:linkAttribute, NSForegroundColorAttributeName:linkColor};
}


- (UIColor *)parseBoxColor:(TFHppleElement *)box {
    NSString *styleString = [box objectForKey:@"style"];
    
    if (!styleString || styleString.length == 0) {
        return [UIColor whiteColor];
    }
    
    NSRegularExpression *regex = [self regexFromPattern:@"background-color:[\\s]*(#[0-9a-f]{6}|[0-9a-f]{3})"];
    if ([self matchString:styleString withRegex:regex]) {
        NSArray *matches = [regex matchesInString:styleString options:0 range:NSMakeRange(0, styleString.length)];
        NSTextCheckingResult *match = [matches lastObject];
        return [self colorAttribute:[styleString substringWithRange:[match rangeAtIndex:1]]];
    }
    
    return [UIColor whiteColor];
}


#pragma mark - utilities
- (NSString *)replaceHtmlEntities:(NSString *)string {
    return [[[[[string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"]
               stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "]
              stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""]
             stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"]
            stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
}


- (NSDictionary *)attributesForFontStyle:(NSString*)style withTrait:(uint32_t)trait {
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
    
    UIFontDescriptor *descriptorWithTrait = [fontDescriptor fontDescriptorWithSymbolicTraits:trait];
    
    UIFont *font =  [UIFont fontWithDescriptor:descriptorWithTrait size: 0.0];
    
    return @{NSFontAttributeName:font};
}


- (BOOL)matchString:(NSString *)string withRegex:(NSRegularExpression *)regex {
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:string options:0 range:(NSRange){0, string.length}];
    
    if (numberOfMatches > 0) {
        return YES;
    } else {
        return NO;
    }
}


- (NSRegularExpression *)regexFromPattern:(NSString *)pattern {
    return [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
}


- (BUCTextBlockAttribute *)setUpBlockAttribute:(NSDictionary *)attributes {
    BUCTextBlockAttribute *parentBlockAttribute = [attributes objectForKey:BUCTextBlockAttributeName];
    BUCTextBlockAttribute *blockAttribute = [[BUCTextBlockAttribute alloc] init];
    
    if (parentBlockAttribute) {
        blockAttribute.padding = parentBlockAttribute.padding + BUCDefaultPadding;
    } else {
        blockAttribute.padding = BUCDefaultPadding;
    }
    
    return blockAttribute;
}


- (void)beginBlock:(NSDictionary *)attributes {
    if (self.output.length == 0) {
        return;
    }
    
    if ([self.output.string characterAtIndex:self.output.length - 1] != '\n') {
        [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:attributes]];
    }
}


- (void)insertNewLine:(NSDictionary *)attributes {
    if (self.output.length == 0) {
        return;
    }
    
    NSMutableDictionary *newLineAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
    [newLineAttributes setObject:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] forKeyedSubscript:NSFontAttributeName];
    [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:newLineAttributes]];
}


- (void)finishBlock:(NSDictionary *)attributes {
    if (self.output.length == 0) {
        return;
    }
    
    if ([self.output.string characterAtIndex:self.output.length - 1] != '\n') {
        [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:attributes]];
    }
}


- (NSURL *)parseImageUrl:(NSString *)source {
    NSString *buBaseUrl = @"http://out.bitunion.org";
    NSURL *url = [NSURL URLWithString:source];
    
    NSRegularExpression *lanRegex = [self regexFromPattern:@"^http://www\\.bitunion\\.org/.+$"];
    NSRegularExpression *relativeRegex = [self regexFromPattern:@"^images/.+$"];
    NSRegularExpression *attachmentRegex = [self regexFromPattern:@"^/attachments/.+$"];
    
    if ([url.host isEqualToString:@"bitunion.org"]) {
        source = [NSString stringWithFormat:@"%@%@", buBaseUrl, url.path];
    } else if ([self matchString:source withRegex:lanRegex]) {
        source = [source stringByReplacingOccurrencesOfString:@"www.bitunion.org" withString:@"out.bitunion.org"];
    } else if ([self matchString:source withRegex:relativeRegex]) {
        source = [NSString stringWithFormat:@"%@/%@", @"http://out.bitunion.org", source];
    } else if ([self matchString:source withRegex:attachmentRegex]) {
        source = [NSString stringWithFormat:@"%@%@", @"http://out.bitunion.org", source];
    }
    
    return [NSURL URLWithString:source];
}


@end


















