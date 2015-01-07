#import "BUCHTMLScraper.h"
#import "TFHpple.h"
#import "BUCConstants.h"
#import "BUCParser.h"


@interface BUCHTMLScraper ()

@property (nonatomic) CGRect imageBounds;
@property (nonatomic) BOOL parseInternetImage;

@end


@implementation BUCHTMLScraper
#pragma mark - public interface
- (instancetype)init {
    self = [super init];
    
    if (self) {
        _imageBounds = CGRectMake(0.0f, 0.0f, 1000.0f, 100.0f);
        _parseInternetImage = [[NSUserDefaults standardUserDefaults] boolForKey:BUCInternetImageSetting];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetImageSettingChanged) name:BUCInternetImageSettingChangedNotification object:nil];
    }
    
    return self;
}


- (void)internetImageSettingChanged {
    _parseInternetImage = [[NSUserDefaults standardUserDefaults] boolForKey:BUCInternetImageSetting];
}


- (NSURL *)avatarUrlFromHtml:(NSString *)html {
    if (!html || html.length == 0 || !_parseInternetImage) {
        return nil;
    }
    
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    NSString *query = @"//body";
    NSArray *nodes = [[[parser searchWithXPathQuery:query] firstObject] children];
    
    NSString *source = [[nodes firstObject] objectForKey:@"src"];
    return [self parseImageUrl:source];
}


- (BUCRichText *)richTextFromHtml:(NSString *)html {
    return [self richTextFromHtml:html textStyle:UIFontTextStyleBody trait:0];
}


- (BUCRichText *)richTextFromHtml:(NSString *)html textStyle:(NSString *)style {
    return [self richTextFromHtml:html textStyle:style trait:0];
}


- (BUCRichText *)richTextFromHtml:(NSString *)html textStyle:(NSString *)style trait:(uint32_t)trait {
    return [self richTextFromTree:[self treeFromHtml:html] attributes:[self attributesForFontStyle:style withTrait:trait]];
}


- (BUCRichText *)richTextFromHtml:(NSString *)html attributes:(NSDictionary *)attributes {
    return [self richTextFromTree:[self treeFromHtml:html] attributes:attributes];
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


- (BUCRichText *)richTextFromTree:(TFHppleElement *)tree attributes:(NSDictionary *)attributes {
    if (!tree) {
        return nil;
    }
    
    BUCRichText *output = [[BUCRichText alloc] init];
    for (TFHppleElement *node in tree.children) {
        if ([node.tagName isEqualToString:@"br"] || [[node objectForKey:@"id"] isEqualToString:@"id_open_api_label"]) {
            continue;
        }
        
        [self appendNode:node output:output superAttributes:attributes];
    }
    
    if (output.richText.length == 0) {
        return nil;
    }
    
    return output;
}


- (void)appendNode:(TFHppleElement *)node output:(BUCRichText *)output superAttributes:(NSDictionary *)superAttributes {
    NSString *tagName = node.tagName;
    
    if ([node isTextNode]) {
        [self appendTextNode:node output:output superAttributes:superAttributes];
    } else if ([tagName isEqualToString:@"img"]) {
        [self appendImageNode:node output:output superAttributes:superAttributes];
    } else if ([tagName isEqualToString:@"center"] || [tagName isEqualToString:@"blockquote"] ||
               [tagName isEqualToString:@"table"] || [tagName isEqualToString:@"ul"] || [tagName isEqualToString:@"ol"]) {
        
        BUCTextBlockAttribute *blockAttribute = [self blockAttributeWithAttribute:superAttributes];
        NSMutableDictionary *thisAttributes = [superAttributes mutableCopy];
        [thisAttributes setObject:blockAttribute forKey:BUCTextBlockAttributeName];
        if (output.richText.length > 0 && [output.richText.string characterAtIndex:output.richText.length - 1] != '\n') {
            [output.richText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:superAttributes]];
        }
        
        [self appendNewLineToRichText:output.richText superAttributes:superAttributes];
        
        NSUInteger location = output.richText.length;
        
        if ([tagName isEqualToString:@"center"]) {
            TFHppleElement *table = node.firstChild;
            NSString *header = table.firstChild.firstChild.firstChild.content;
            TFHppleElement *content = [table.children objectAtIndex:1];
            content = content.firstChild.firstChild.firstChild.firstChild;
            
            if ([header rangeOfString:@"引用"].length > 0) {
                [self appendQuoteNode:content output:output superAttributes:thisAttributes];
            } else if ([header rangeOfString:@"代码"].length > 0) {
                content = content.firstChild.firstChild;
                [self appendCodeNode:content output:output superAttributes:thisAttributes];
            }
            
        } else if ([tagName isEqualToString:@"table"]) {
            TFHppleElement *codeNode = node.firstChild.firstChild.firstChild.firstChild.firstChild;
            [self appendCodeNode:codeNode output:output superAttributes:thisAttributes];
        } else if ([tagName isEqualToString:@"blockquote"]) {
            TFHppleElement *box = [node.children objectAtIndex:1];
            blockAttribute.backgroundColor = [self colorAttributeOfBox:box];
            [self appendBoxNode:box output:output superAttributes:thisAttributes];
        } else {
            blockAttribute.noBackground = YES; // do not draw background for list
            [self appendListNode:node output:output superAttributes:thisAttributes];
        }
        
        if (output.richText.length == 0 || [output.richText.string characterAtIndex:output.richText.length - 1] != '\n') {
            [output.richText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:thisAttributes]];
        }
        
        NSUInteger length = output.richText.length - location;
        blockAttribute.range = NSMakeRange(location, length);
        if (!output.blockList) {
            output.blockList = [[NSMutableArray alloc] init];
        }
        [output.blockList addObject:blockAttribute];
        [self appendNewLineToRichText:output.richText superAttributes:superAttributes];
    } else {
        NSDictionary *attributes;
        NSUInteger location = output.richText.length;
        
        if ([tagName isEqualToString:@"a"]) {
            if ([node.firstChild.content rangeOfString:@"复制到剪贴板"].length > 0) {
                return;
            }
            attributes = [self linkAttributes:node];
        } else if ([tagName isEqualToString:@"font"]) {
            attributes = [self fontAttributes:node];
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
        
        for (TFHppleElement *childNode in node.children) {
            if ([node.tagName isEqualToString:@"br"] || [[node objectForKey:@"id"] isEqualToString:@"id_open_api_label"]) {
                continue;
            }
            
            [self appendNode:childNode output:output superAttributes:attributes];
        }
        
        
        if ([tagName isEqualToString:@"a"]) {
            NSUInteger length = output.richText.length - location;
            BUCLinkAttribute *linkAttribute = [thisAttributes objectForKey:BUCLinkAttributeName];
            linkAttribute.range = NSMakeRange(location, length);
        }
    }
}


#pragma mark - inline elements
- (void)appendTextNode:(TFHppleElement *)node output:(BUCRichText *)output superAttributes:(NSDictionary *)superAttributes {
    if (!node.content || node.content.length == 0) {
        return;
    }
    
    NSMutableDictionary *attributes = [superAttributes mutableCopy];
    
    if (matchPattern(node.content, @"\\s*\\[ Last edited by .+ on [0-9]{4}-[0-9]{1,2}-[0-9]{1,2} at [0-9]{2}:[0-9]{2} \\]", NULL)) {
        [attributes setObject:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] forKeyedSubscript:NSFontAttributeName];
    } else if (matchPattern(node.content, @"^\\s*[a-zA-Z]+\\s*代码\\s*$", NULL)) {
        [self appendNewLineToRichText:output.richText superAttributes:superAttributes];
        [self appendNewLineToRichText:output.richText superAttributes:superAttributes];
    }
    
    BUCDiscuzContext *context = BUCDiscuzNewContext([self replaceHtmlEntities:node.content], output.richText, attributes);
    parseContext(context);
    BUCDiscuzFreeContext(context);
}


- (void)appendImageNode:(TFHppleElement *)imageNode output:(BUCRichText *)output superAttributes:(NSDictionary *)superAttributes {
    NSString *source = [imageNode objectForKey:@"src"];
    if (!source || source.length == 0) {
        return;
    }
    
    BUCImageAttachment *attachment = [[BUCImageAttachment alloc] init];
    BOOL emotionFlag = NO;
    if (matchPattern(source, @"^\\.\\./images/.+$", NULL)) {
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        attachment.path = [NSString stringWithFormat:@"%@/%@", resourcePath, [source substringFromIndex:3]];
        UIImage *image = [self.dataManager getImageWithPath:attachment.path];
        if (!image) {
            return;
        } else {
            if (image.size.width <= 20.0f) {
                // the size less than 20 may cause text kit to failed to typesetting
                attachment.bounds = CGRectMake(0.0f, 0.0f, 25.0f, 25.0f);
            } else {
                attachment.bounds = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
            }
            emotionFlag = YES;
        }
    } else if (self.parseInternetImage){
        attachment.url = [self parseImageUrl:source];
        if (!attachment.url) {
            return;
        } else {
            attachment.bounds = self.imageBounds;
        }
    } else {
        return;
    }
    
    attachment.glyphIndex = output.richText.length;
    if (emotionFlag) {
        if (!output.emotionList) {
            output.emotionList = [[NSMutableArray alloc] init];
        }
        [output.emotionList addObject:attachment];
    } else {
        if (!output.imageList) {
            output.imageList = [[NSMutableArray alloc] init];
        }
        [output.imageList addObject:attachment];
    }
    
    [output.richText appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    [output.richText addAttributes:superAttributes range:NSMakeRange(output.richText.length - 1, 1)];
}


#pragma mark - block elements
- (void)appendQuoteNode:(TFHppleElement *)quoteNode output:(BUCRichText *)output superAttributes:(NSDictionary *)superAttributes {
    if (!quoteNode || !quoteNode.children || quoteNode.children.count == 0) {
        return;
    }
    
    for (TFHppleElement *node in quoteNode.children) {
        if ([node.tagName isEqualToString:@"br"] || [node.tagName isEqualToString:@"span"]) {
            continue;
        }
        
        [self appendNode:node output:output superAttributes:superAttributes];
    }
}


- (void)appendCodeNode:(TFHppleElement *)codeNode output:(BUCRichText *)output superAttributes:(NSDictionary *)superAttributes {
    
    if (!codeNode.children || codeNode.children.count == 0) {
        return;
    }
    
    for (TFHppleElement *node in codeNode.children) {
        if ([node.tagName isEqualToString:@"br"] || [node.tagName isEqualToString:@"span"]) {
            continue;
        }

        [self appendNode:node output:output superAttributes:superAttributes];
        [output.richText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:superAttributes]];
    }
}


- (void)appendBoxNode:(TFHppleElement *)boxNode output:(BUCRichText *)output superAttributes:(NSDictionary *)superAttributes {
    for (TFHppleElement *node in boxNode.children) {
        if ([node.tagName isEqualToString:@"br"] || [node.tagName isEqualToString:@"span"]) {
            continue;
        }
        
        [self appendNode:node output:output superAttributes:superAttributes];
    }
}


- (void)appendListNode:(TFHppleElement *)listNode output:(BUCRichText *)output superAttributes:(NSDictionary *)superAttributes {
    for (TFHppleElement *node in listNode.children) {
        if ([node.tagName isEqualToString:@"br"] || [node.tagName isEqualToString:@"span"]) {
            continue;
        }
        
        [output.richText appendAttributedString:[[NSAttributedString alloc] initWithString:@"• " attributes:superAttributes]];
        [self appendNode:node output:output superAttributes:superAttributes];
        [output.richText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:superAttributes]];
    }
}


#pragma mark - attributes parsing
- (NSDictionary *)fontAttributes:(TFHppleElement *)font {
    NSMutableDictionary *fontAttributes = [[NSMutableDictionary alloc] init];
    
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
                       @"#cc3333":    [UIColor colorWithRed:204.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1.0f]
                       };
    });
    
    UIColor *output = [colorTable objectForKey:[color lowercaseString]];
    
    if (output) {
        return output;
    }
    
    if (!matchPattern(color, @"^#\\s*([a-z0-9]{3}|[a-z0-9]{6})$", NULL)) {
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
    
    if (matchPattern(href, @"^/profile-username-.+\\.html$", &match)) {
        linkAttribute.linkType = BUCUrlLink;
        linkAttribute.linkValue = [NSString stringWithFormat:@"%@%@", self.dataManager.host, href];
        linkColor = [self colorAttribute:@"url"];
    } else if (matchPattern(href, @"^(http://)?(((www)|(out)|(us))\\.)?bitunion\\.org(/.*)?$", &match)) {
        NSRange hostRange = [href rangeOfString:@"bitunion.org"];
        NSUInteger pathIndex = hostRange.location + hostRange.length;
        NSString *path;
        if (pathIndex < href.length) {
            path = [href substringFromIndex:pathIndex];
        }
        
        if (matchPattern(path, @"^/thread-([1-9][0-9]+)-[1-9]-[1-9]\\.html$", &match) ||
            matchPattern(path, @"^/viewthread\\.php\\?tid=([1-9][0-9]+).*$", &match)) {
            linkAttribute.linkType = BUCPostLink;
            linkAttribute.linkValue = [path substringWithRange:[match rangeAtIndex:1]];
            linkColor = [UIColor orangeColor];
        }
    }
    
    if (!linkAttribute.linkValue) {
        linkAttribute.linkType = BUCUrlLink;
        linkAttribute.linkValue = href;
        linkColor = [UIColor colorWithRed:0 green:122.0f/255.0f blue:1.0f alpha:1.0f];
    }
    
    return @{BUCLinkAttributeName:linkAttribute, NSForegroundColorAttributeName:linkColor};
}


- (UIColor *)colorAttributeOfBox:(TFHppleElement *)box {
    NSString *styleString = [box objectForKey:@"style"];
    
    if (!styleString || styleString.length == 0) {
        return [UIColor whiteColor];
    }
    
    NSTextCheckingResult *match;
    if (matchPattern(styleString, @"background-color:\\s*(#[0-9a-f]{6}|[0-9a-f]{3})", &match)) {
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


- (BUCTextBlockAttribute *)blockAttributeWithAttribute:(NSDictionary *)attributes {
    BUCTextBlockAttribute *parentBlockAttribute = [attributes objectForKey:BUCTextBlockAttributeName];
    BUCTextBlockAttribute *blockAttribute = [[BUCTextBlockAttribute alloc] init];
    
    if (parentBlockAttribute) {
        blockAttribute.padding = parentBlockAttribute.padding + BUCDefaultPadding;
    } else {
        blockAttribute.padding = BUCDefaultPadding;
    }
    
    return blockAttribute;
}


- (void)appendNewLineToRichText:(NSMutableAttributedString *)output superAttributes:(NSDictionary *)superAttributes {
    NSMutableDictionary *newLineAttributes = [superAttributes mutableCopy];
    [newLineAttributes setObject:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] forKey:NSFontAttributeName];
    [output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:newLineAttributes]];
}


- (NSURL *)parseImageUrl:(NSString *)source {
    NSURL *url = [NSURL URLWithString:source];
    
    if ([url.host isEqualToString:@"bitunion.org"] || [url.host isEqualToString:@"v6.bitunion.org"]) {
        source = [NSString stringWithFormat:@"%@%@", self.dataManager.host, url.path];
    } else if (matchPattern(source, @"^http://www\\.bitunion\\.org/.+$", NULL)) {
        source = [source stringByReplacingOccurrencesOfString:@"http://www.bitunion.org" withString:self.dataManager.host];
    } else if (matchPattern(source, @"^images/.+$", NULL)) {
        source = [NSString stringWithFormat:@"%@/%@", self.dataManager.host, source];
    } else if (matchPattern(source, @"^/attachments/.+$", NULL)) {
        source = [NSString stringWithFormat:@"%@%@", self.dataManager.host, source];
    }
    
    return [NSURL URLWithString:source];
}


@end


















