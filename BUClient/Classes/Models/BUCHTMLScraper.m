#import "BUCHTMLScraper.h"
#import "TFHpple.h"
#import "UIImage+BUCImageCategory.h"
#import "BUCConstants.h"
#import "BUCModels.h"


@interface BUCHTMLScraper ()

@property (nonatomic) NSMutableAttributedString *output;
@property (nonatomic) NSMutableArray *attachmentList;
@property (nonatomic) NSMutableArray *blockList;
@property (nonatomic) CGFloat imageWidth;

@end


@implementation BUCHTMLScraper
#pragma mark - public interface
- (instancetype)init {
    self = [super init];
    
    if (self) {
        _imageWidth = CGRectGetWidth([UIScreen mainScreen].bounds) - 2 * BUCDefaultMargin;
    }
    
    return self;
}


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
    return [self richTextFromHtml:html textStyle:UIFontTextStyleBody trait:0];
}


- (NSAttributedString *)richTextFromHtml:(NSString *)html attributes:(NSDictionary *)attributes {
    return [self richTextFromTree:[self treeFromHtml:html] attributes:attributes];
}


- (NSAttributedString *)richTextFromHtml:(NSString *)html textStyle:(NSString *)style {
    return [self richTextFromHtml:html textStyle:style trait:0];
}


- (NSAttributedString *)richTextFromHtml:(NSString *)html textStyle:(NSString *)style trait:(uint32_t)trait {
    return [self richTextFromTree:[self treeFromHtml:html] attributes:[self attributesForFontStyle:style withTrait:trait]];
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


- (NSAttributedString *)richTextFromTree:(TFHppleElement *)tree attributes:(NSDictionary *)attributes {
    if (!tree) {
        return nil;
    }
    
    if (!attributes) {
        attributes = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
    }
    
    self.output = [[NSMutableAttributedString alloc] init];
    
    for (TFHppleElement *node in tree.children) {
        if ([node.tagName isEqualToString:@"br"] || [node.tagName isEqualToString:@"span"]) {
            continue;
        }
        
        [self appendRichText:node superAttributes:attributes];
    }
    
    if (self.output.length == 0) {
        return nil;
    }
    
    if (self.attachmentList) {
        [self.output addAttribute:BUCAttachmentListAttributeName value:self.attachmentList range:NSMakeRange(0, 1)];
        self.attachmentList = nil;
    }
    
    if (self.blockList) {
        [self.output addAttribute:BUCTextBlockListAttributeName value:self.blockList range:NSMakeRange(0, 1)];
        self.blockList = nil;
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
            TFHppleElement *table = tree.firstChild;
            NSString *header = table.firstChild.firstChild.firstChild.content;
            TFHppleElement *content = [table.children objectAtIndex:1];
            content = content.firstChild.firstChild.firstChild.firstChild;
            
            if ([header rangeOfString:@"引用"].length > 0) {
                location = self.output.length;
                [self appendQuote:content superAttributes:thisAttributes];
            } else if ([header rangeOfString:@"代码"].length > 0) {
                location = self.output.length;
                [self appendCode:content superAttributes:thisAttributes];
            }

        } else if ([tagName isEqualToString:@"blockquote"]) {
            TFHppleElement *box = [tree.children objectAtIndex:1];
            blockAttribute.backgroundColor = [self colorAttributeOfBox:box];
            [self appendBox:box superAttributes:thisAttributes];
        } else {
            blockAttribute.noBackground = YES; // do not draw background for list
            [self appendList:tree superAttributes:thisAttributes];
        }
        
        [self finishBlock:thisAttributes];
        NSUInteger length = self.output.length - location;
        blockAttribute.range = NSMakeRange(location, length);
        if (!self.blockList) {
            self.blockList = [[NSMutableArray alloc] init];
        }
        [self.blockList addObject:blockAttribute];
        [self insertNewLine:superAttributes];
    } else {
        NSDictionary *attributes;
        NSUInteger location = self.output.length;
        
        if ([tagName isEqualToString:@"a"]) {
            attributes = [self linkAttributes:tree];
        } else if ([tagName isEqualToString:@"font"]) {
            attributes = [self fontAttributes:tree];
        } else if ([tagName isEqualToString:@"b"]) {
            attributes = [self attributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitBold];
        } else if ([tagName isEqualToString:@"i"]) {
            attributes = [self attributesForFontStyle:UIFontTextStyleBody withTrait:UIFontDescriptorTraitItalic];
        } else if ([tagName isEqualToString:@"u"]) {
            attributes = @{NSUnderlineStyleAttributeName:@1};
        }
        
        NSMutableDictionary *thisAttributes;
        if (attributes) {
            thisAttributes = [superAttributes mutableCopy];
            [thisAttributes addEntriesFromDictionary:attributes];
            attributes = (NSDictionary *)thisAttributes;
        } else {
            attributes = superAttributes;
        }
        
        for (TFHppleElement *node in tree.children) {
            if ([node.tagName isEqualToString:@"br"] || [node.tagName isEqualToString:@"span"]) {
                continue;
            }
            
            [self appendRichText:node superAttributes:attributes];
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
    
    if ([self matchString:tree.content withPattern:@"\\s*\\[ Last edited by .+ on [0-9]{4}-[0-9]{1,2}-[0-9]{1,2} at [0-9]{2}:[0-9]{2} \\]" match:NULL]) {
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
    
    if ([self matchString:source withPattern:@"^\\.\\./images/.+$" match:NULL]) {
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        attachment.path = [NSString stringWithFormat:@"%@/%@", resourcePath, [source substringFromIndex:3]];
        UIImage *image = [self.dataManager getImageWithPath:attachment.path];
        if (!image) {
            return;
        } else {
            attachment.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
        }
    } else {
        attachment.url = [self parseImageUrl:source];
        if (!attachment.url) {
            return;
        } else {
            attachment.bounds = CGRectMake(0, 0, self.imageWidth, 100.0f);
        }
    }
    
    attachment.glyphIndex = [self.output length];
    if (!self.attachmentList) {
        self.attachmentList = [[NSMutableArray alloc] init];
    }
    [self.attachmentList addObject:attachment];
    [self.output appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    [self.output addAttributes:superAttributes range:NSMakeRange(self.output.length - 1, 1)];
}


#pragma mark - block elements
- (void)appendQuote:(TFHppleElement *)tree superAttributes:(NSDictionary *)superAttributes {
    if (!tree || !tree.children || tree.children.count == 0) {
        return;
    }
    
    for (TFHppleElement *node in tree.children) {
        if ([node.tagName isEqualToString:@"br"] || [node.tagName isEqualToString:@"span"]) {
            continue;
        }
        
        [self appendRichText:node superAttributes:superAttributes];
    }
}


- (void)appendBox:(TFHppleElement *)tree superAttributes:(NSDictionary *)superAttributes {
    for (TFHppleElement *node in tree.children) {
        if ([node.tagName isEqualToString:@"br"] || [node.tagName isEqualToString:@"span"]) {
            continue;
        }
        
        [self appendRichText:node superAttributes:superAttributes];
    }
}


- (void)appendCode:(TFHppleElement *)tree superAttributes:(NSDictionary *)superAttributes {
    NSArray *codeLines = [tree searchWithXPathQuery:@"//div/ol/li"];
    
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
    for (TFHppleElement *node in tree.children) {
        if ([node.tagName isEqualToString:@"br"] || [node.tagName isEqualToString:@"span"]) {
            continue;
        }
        
        [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:@"• " attributes:superAttributes]];
        
        if ([node.firstChild isTextNode] && node.firstChild.content) {
            NSString *buffer = [NSString stringWithFormat:@"%@", node.firstChild.content];
            [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:buffer attributes:superAttributes]];
        } else {
            [self appendRichText:node superAttributes:superAttributes];
        }
        
        [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:superAttributes]];
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
                       @"#cc3333":    [UIColor colorWithRed:204.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1.0f],
                       @"mail":       [UIColor colorWithRed:0 green:128.0f/255.0f blue:1.0f alpha:1.0f],
                       @"url":        [UIColor colorWithRed:0 green:122.0f/255.0f blue:1.0f alpha:1.0f]
                       };
    });
    
    UIColor *output = [colorTable objectForKey:[color lowercaseString]];
    
    if (output) {
        return output;
    }
    
    if (![self matchString:color withPattern:@"^#\\s*([a-z0-9]{3}|[a-z0-9]{6})$" match:NULL]) {
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
    
    BUCLinkAttribute *linkAttribute = [[BUCLinkAttribute alloc] init];
    NSTextCheckingResult *match;
    UIColor *linkColor;
    
    if ([self matchString:href withPattern:@"^/profile-username-.+\\.html$" match:&match]) {
        linkAttribute.linkType = BUCUrlLink;
        linkAttribute.linkValue = [NSString stringWithFormat:@"%@%@", self.dataManager.host, href];
        linkColor = [self colorAttribute:@"url"];
    } else if ([self matchString:href withPattern:@"^(http://)?(((www)|(out)|(us))\\.)?bitunion\\.org(/.*)?$" match:&match]) {
        NSRange hostRange = [href rangeOfString:@"bitunion.org"];
        NSUInteger pathIndex = hostRange.location + hostRange.length;
        NSString *path;
        if (pathIndex < href.length) {
            path = [href substringFromIndex:pathIndex];
        }
        
        if ([self matchString:path withPattern:@"^/thread-([1-9][0-9]+)-[1-9]-[1-9]\\.html$" match:&match] ||
            [self matchString:path withPattern:@"^/viewthread\\.php\\?tid=([1-9][0-9]+).*$" match:&match]) {
            linkAttribute.linkType = BUCPostLink;
            linkAttribute.linkValue = [path substringWithRange:[match rangeAtIndex:1]];
            linkColor = [self colorAttribute:@"orange"];
        } else {
            linkAttribute.linkType = BUCUrlLink;
            linkAttribute.linkValue = href;
            linkColor = [self colorAttribute:@"url"];
        }
    } else if ([self matchString:href withPattern:@"^mailto:.+$" match:&match]) {
        linkAttribute.linkType = BUCMailLink;
        linkAttribute.linkValue = [href substringFromIndex:7];
        linkColor = [self colorAttribute:@"mail"];
    } else {
        linkAttribute.linkType = BUCUrlLink;
        linkAttribute.linkValue = href;
        linkColor = [self colorAttribute:@"url"];
    }
    
    return @{BUCLinkAttributeName:linkAttribute, NSForegroundColorAttributeName:linkColor};
}


- (UIColor *)colorAttributeOfBox:(TFHppleElement *)box {
    NSString *styleString = [box objectForKey:@"style"];
    
    if (!styleString || styleString.length == 0) {
        return [UIColor whiteColor];
    }
    
    NSTextCheckingResult *match;
    if ([self matchString:styleString withPattern:@"background-color:\\s*(#[0-9a-f]{6}|[0-9a-f]{3})" match:&match]) {
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
    
    if (trait > 0) {
        fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:trait];
    }
    
    UIFont *font =  [UIFont fontWithDescriptor:fontDescriptor size: 0.0];
    
    return @{NSFontAttributeName:font};
}


- (BOOL)matchString:(NSString *)string withPattern:(NSString *)pattern match:(NSTextCheckingResult **)match {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
    
    NSTextCheckingResult *output = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    
    if (output.numberOfRanges > 0) {
        if (match) {
            *match = output;
        }
        
        return YES;
    }
    
    return NO;
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
    NSMutableDictionary *newLineAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
    [newLineAttributes setObject:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] forKeyedSubscript:NSFontAttributeName];
    [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:newLineAttributes]];
}


- (void)finishBlock:(NSDictionary *)attributes {    
    if (self.output.length == 0 || [self.output.string characterAtIndex:self.output.length - 1] != '\n') {
        [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:attributes]];
    }
}


- (NSURL *)parseImageUrl:(NSString *)source {
    NSURL *url = [NSURL URLWithString:source];
    
    if ([url.host isEqualToString:@"bitunion.org"] || [url.host isEqualToString:@"v6.bitunion.org"]) {
        source = [NSString stringWithFormat:@"%@%@", self.dataManager.host, url.path];
    } else if ([self matchString:source withPattern:@"^http://www\\.bitunion\\.org/.+$" match:NULL]) {
        source = [source stringByReplacingOccurrencesOfString:@"http://www.bitunion.org" withString:self.dataManager.host];
    } else if ([self matchString:source withPattern:@"^images/.+$" match:NULL]) {
        source = [NSString stringWithFormat:@"%@/%@", self.dataManager.host, source];
    } else if ([self matchString:source withPattern:@"^/attachments/.+$" match:NULL]) {
        source = [NSString stringWithFormat:@"%@%@", self.dataManager.host, source];
    }
    
    return [NSURL URLWithString:source];
}


@end


















