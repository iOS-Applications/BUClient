//
//  BUCDiscuzParse.h
//  BUClient
//
//  Created by zty on 12/25/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifndef BUClient_BUCDiscuzParse_h
#define BUClient_BUCDiscuzParse_h
typedef NS_OPTIONS(uint8_t, BUCDiscuzToken) {
    buc_token_left_bracket = 1 << 0,
    buc_token_right_bracket = 1 << 1,
    buc_token_string = 1 << 2,
    buc_token_null = 1 << 3
};

typedef NS_OPTIONS(uint8_t, BUCDiscuzTag) {
    buc_discuz_tag_strike = 1 << 0,
    buc_discuz_tag_strike_close = 1 << 1,
    buc_discuz_tag_video = 1 << 2,
    buc_discuz_tag_video_close = 1 << 3,
    buc_discuz_tag_invalid = 1 << 4
};

typedef struct {
    char *source;
    char *rest;
    int minBufferSize;
    size_t bufferSize;
    char *buffer;
    BUCDiscuzToken lastToken;
    __unsafe_unretained NSMutableAttributedString *product;
    __unsafe_unretained NSDictionary *attributes;
    
} BUCDiscuzContext;


BUCDiscuzContext *BUCDiscuzNewContext(NSString *string, NSMutableAttributedString *product, NSDictionary *attributes);
void BUCDiscuzFreeContext(BUCDiscuzContext *context);
void parseContext(BUCDiscuzContext *context);


#endif
