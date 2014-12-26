#import "BUCParser.h"
#import "BUCModels.h"
#import "BUCConstants.h"


BUCDiscuzContext *BUCDiscuzNewContext(NSString *string, NSMutableAttributedString *product, NSDictionary *attributes) {
    BUCDiscuzContext *newContext = malloc(sizeof *newContext);
    if (newContext == NULL) {
        return nil;
    }
    newContext->source = (char *)[string UTF8String];
    newContext->rest = (char *)newContext->source;
    newContext->minBufferSize = 1024;
    newContext->bufferSize = 1024;
    newContext->buffer = malloc(1024);
    newContext->product = product;
    newContext->attributes = attributes;
    return newContext;
}


void BUCDiscuzFreeContext(BUCDiscuzContext *context) {
    free(context->buffer);
    free(context);
}

BOOL matchPattern(NSString *string, NSString *pattern, NSTextCheckingResult **match) {
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

#pragma mark - private functions
void nextToken(BUCDiscuzContext *context) {
    const char *source = context->rest;
    size_t maxSize = context->bufferSize;
    NSUInteger index = 0;
    char lastChar = source[0];
    char *buffer = context->buffer;
    while (lastChar != '\0' && lastChar != '[' && lastChar != ']') {
        if (index == maxSize) {
            maxSize = maxSize + context->minBufferSize;
            context->bufferSize = maxSize;
            context->buffer = reallocf(buffer, maxSize);
            buffer = context->buffer;
            if (buffer == NULL) {
                context->lastToken = buc_token_null;
                return;
            }
        }
        
        buffer[index] = lastChar;
        index = index + 1;
        lastChar = source[index];
    }
    
    if (index == maxSize) {
        maxSize = maxSize + context->minBufferSize;
        context->bufferSize = maxSize;
        context->buffer = reallocf(buffer, maxSize);
        buffer = context->buffer;
        if (buffer == NULL) {
            context->lastToken = buc_token_null;
            return;
        }
    }
    
    if (index > 0) {
        context->lastToken = buc_token_string;
    } else if (lastChar == '[' || lastChar == ']') {
        buffer[0] = lastChar;
        index = index + 1;
        if (lastChar == '[') {
            context->lastToken = buc_token_left_bracket;
        } else {
            context->lastToken = buc_token_right_bracket;
        }
    } else {
        context->lastToken = buc_token_null;
        return;
    }
    
    buffer[index] = '\0';
    context->rest = context->rest + index;
}


BUCDiscuzTag parseOpenTag(BUCDiscuzContext *context) {
    char *temp = "[";
    nextToken(context);
    BUCDiscuzToken token = context->lastToken;
    if (token == buc_token_string) {
        if (strcmp((const char *)context->buffer, "s") == 0) {
            temp = "[s";
            if (context->rest[0] == ']') {
                context->rest = context->rest + 1;
                nextToken(context);
                return buc_discuz_tag_strike;
            }
        } else if (strcmp((const char *)context->buffer, "video") == 0) {
            temp = "[video";
            if (context->rest[0] == ']') {
                context->rest = context->rest + 1;
                nextToken(context);
                return buc_discuz_tag_video;
            }
        }
    }
    
    [context->product appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(const char *)temp] attributes:context->attributes]];
    
    if (token == buc_token_left_bracket || token == buc_token_null) {
        return buc_discuz_tag_invalid;
    }
    
    [context->product appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(const char *)context->buffer] attributes:context->attributes]];
    
    if (context->rest[0] == ']') {
        temp = "]";
        [context->product appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(const char *)temp] attributes:context->attributes]];
        context->rest = context->rest + 1;
    }
    
    nextToken(context);
    return buc_discuz_tag_invalid;
}


BUCDiscuzTag parseCloseTag(BUCDiscuzContext *context) {
    char *temp = "[/";
    nextToken(context);
    BUCDiscuzToken token = context->lastToken;
    if (token == buc_token_string) {
        if (strcmp((const char *)context->buffer, "s") == 0) {
            temp = "[/s";
            if (context->rest[0] == ']') {
                context->rest = context->rest + 1;
                nextToken(context);
                return buc_discuz_tag_strike_close;
            }
        } else if (strcmp((const char *)context->buffer, "video") == 0) {
            temp = "[/video";
            if (context->rest[0] == ']') {
                context->rest = context->rest + 1;
                nextToken(context);
                return buc_discuz_tag_video_close;
            }
        }
    }
    
    [context->product appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(const char *)temp] attributes:context->attributes]];
    
    if (token == buc_token_left_bracket || token == buc_token_null) {
        return buc_discuz_tag_invalid;
    }
    
    [context->product appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(const char *)context->buffer] attributes:context->attributes]];
    
    if (context->rest[0] == ']') {
        temp = "]";
        [context->product appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(const char *)temp] attributes:context->attributes]];
        context->rest = context->rest + 1;
    }
    
    nextToken(context);
    return buc_discuz_tag_invalid;
}


void appendVideo(BUCDiscuzContext *context, NSString *flashUrl) {
    NSTextCheckingResult *match;
    NSString *htmlUrl;
    if (matchPattern(flashUrl, @"^http://player.youku.com/player.php/sid/([a-z0-9]+)/v.swf$", &match)) {
        htmlUrl = [NSString stringWithFormat:@"http://v.youku.com/v_show/id_%@.html", [flashUrl substringWithRange:[match rangeAtIndex:1]]];
    } else if (matchPattern(flashUrl, @"^http://player.video.qiyi.com/[a-z0-9]+/[0-9]+/[0-9]+/(v_[0-9a-z]+).swf.+$", &match)) {
        htmlUrl = [NSString stringWithFormat:@"http://www.iqiyi.com/%@.html", [flashUrl substringWithRange:[match rangeAtIndex:1]]];
    } else if (matchPattern(flashUrl, @"^http://i7.imgs.letv.com/player/swfPlayer.swf\\?id=([0-9]+).+$", &match)) {
        htmlUrl = [NSString stringWithFormat:@"http://www.letv.com/ptv/vplay/%@.html", [flashUrl substringWithRange:[match rangeAtIndex:1]]];
    } else if (matchPattern(flashUrl, @"^http://www.tucao.cc/mini/([0-9]+).swf$", &match)) {
        htmlUrl = [NSString stringWithFormat:@"http://www.tucao.cc/play/h%@/", [flashUrl substringWithRange:[match rangeAtIndex:1]]];
    } else {
        htmlUrl = flashUrl;
    }
    
    BUCLinkAttribute *linkAttribute = [[BUCLinkAttribute alloc] init];
    linkAttribute.linkType = BUCUrlLink;
    linkAttribute.linkValue = htmlUrl;
    linkAttribute.range = NSMakeRange(context->product.length, htmlUrl.length);
    NSMutableDictionary *attributes = [context->attributes mutableCopy];
    [attributes setObject:[UIColor colorWithRed:0 green:122.0f/255.0f blue:1.0f alpha:1.0f] forKey:NSForegroundColorAttributeName];
    [attributes setObject:linkAttribute forKey:BUCLinkAttributeName];
    [context->product appendAttributedString:[[NSAttributedString alloc] initWithString:htmlUrl attributes:attributes]];
}


void parseVideo(BUCDiscuzContext *context) {
    char *save;
    
    if (context->lastToken == buc_token_string) {
        appendVideo(context, [NSString stringWithUTF8String:(const char *)context->buffer]);
        if (context->rest[0] == '[' && context->rest[1] == '/') {
            save = context->rest;
            context->rest = context->rest + 2;
            if (parseCloseTag(context) != buc_discuz_tag_video_close) {
                context->rest = save;
            }
        }
        
        nextToken(context);
    }
}


void parseStrike(BUCDiscuzContext *context) {
    BUCDiscuzTag tag;
    while (context->lastToken != buc_token_null) {
        switch (context->lastToken) {
            case buc_token_string:
                [context->product appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(const char *)context->buffer] attributes:context->attributes]];
                nextToken(context);
                break;
                
            case buc_token_left_bracket:
                if (context->rest[0] == '/') {
                    context->rest = context->rest + 1;
                    if (parseCloseTag(context) == buc_discuz_tag_strike_close) {
                        return;
                    }
                } else {
                    tag = parseOpenTag(context);
                    if (tag == buc_discuz_tag_strike) {
                        parseStrike(context);
                    } else if (tag == buc_discuz_tag_video) {
                        parseVideo(context);
                    }
                }
                break;
            default:
                break;
        }
    }
}


void parseContext(BUCDiscuzContext *context) {
    nextToken(context);
    BUCDiscuzTag tag;
    while (context->lastToken != buc_token_null) {
        switch (context->lastToken) {
            case buc_token_string:
                [context->product appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(const char *)context->buffer] attributes:context->attributes]];
                nextToken(context);
                break;
                
            case buc_token_left_bracket:
                if (context->rest[0] == '/') {
                    context->rest = context->rest + 1;
                    parseCloseTag(context);
                } else {
                    tag = parseOpenTag(context);
                    if (tag == buc_discuz_tag_strike) {
                        NSDictionary *save = context->attributes;
                        NSMutableDictionary *strikeAttributes = [context->attributes mutableCopy];
                        [strikeAttributes setObject:@(NSUnderlineStyleSingle) forKey:NSStrikethroughStyleAttributeName];
                        context->attributes = strikeAttributes;
                        parseStrike(context);
                        context->attributes = save;
                    } else if (tag == buc_discuz_tag_video) {
                        parseVideo(context);
                    }
                }
                break;
            default:
                break;
        }
    }
}








