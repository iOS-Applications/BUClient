#import "BUCDiscuzParse.h"


BUCDiscuzContext *BUCDiscuzNewContext(NSString *string, NSMutableAttributedString *product, NSDictionary *attributes) {
    BUCDiscuzContext init = {
        .source = (const unsigned char *)[string UTF8String]
    };
    BUCDiscuzContext *newContext = malloc(sizeof *newContext);
    if (newContext == NULL) {
        return nil;
    }
    memcpy(newContext, &init, sizeof *newContext);
    newContext->rest = (unsigned char *)newContext->source;
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


void nextToken(BUCDiscuzContext *context) {
    unsigned char *source = context->rest;
    size_t maxSize = context->bufferSize;
    NSUInteger index = 0;
    unsigned char lastChar = source[0];
    unsigned char *buffer = context->buffer;
    while (lastChar != '\0' && lastChar != '[' && lastChar != ']') {
        if (lastChar == '/' && source[index + 1] == ']') {
            break;
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
    } else if (lastChar == '/') {
        buffer[0] = '/';
        buffer[1] = ']';
        index = index + 2;
        context->lastToken = buc_token_slash_right_bracket;
    } else {
        context->lastToken = buc_token_null;
        return;
    }
    
    buffer[index] = '\0';
    context->rest = context->rest + index;
}


BUCDiscuzTag parseOpenTag(BUCDiscuzContext *context) {
    unsigned char temp[8];
    temp[0] = '[';
    temp[1] = '\0';
    nextToken(context);
    BUCDiscuzToken token = context->lastToken;
    if (token == buc_token_string) {
        if (strcmp((const char *)context->buffer, "s") == 0) {
            memcpy(temp + 1, context->buffer, 2);
            if (context->rest[0] == ']') {
                context->rest = context->rest + 1;
                nextToken(context);
                return buc_discuz_tag_strike;
            }
        } else if (strcmp((const char *)context->buffer, "video") == 0) {
            memcpy(temp + 1, context->buffer, 6);
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
        temp[0] = ']';
        temp[1] = '\0';
        [context->product appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(const char *)temp] attributes:context->attributes]];
        context->rest = context->rest + 1;
    }
    
    nextToken(context);
    return buc_discuz_tag_invalid;
}


BUCDiscuzTag parseCloseTag(BUCDiscuzContext *context) {
    unsigned char temp[8];
    temp[0] = '[';
    temp[1] = '/';
    temp[2] = '\0';
    nextToken(context);
    BUCDiscuzToken token = context->lastToken;
    if (token == buc_token_string) {
        if (strcmp((const char *)context->buffer, "s") == 0) {
            memcpy(temp + 2, context->buffer, 2);
            if (context->rest[0] == ']') {
                context->rest = context->rest + 1;
                nextToken(context);
                return buc_discuz_tag_strike_close;
            }
        } else if (strcmp((const char *)context->buffer, "video") == 0) {
            memcpy(temp + 2, context->buffer, 6);
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
        temp[0] = ']';
        temp[1] = '\0';
        [context->product appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(const char *)temp] attributes:context->attributes]];
        context->rest = context->rest + 1;
    }
    
    nextToken(context);
    return buc_discuz_tag_invalid;
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
                        
                    }
                }
                break;
            default:
                break;
        }
    }
}








