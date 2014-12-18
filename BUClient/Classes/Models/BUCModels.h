#import <Foundation/Foundation.h>
#include "BUCTextStack.h"

#ifndef BUClient_BUCModels_h
#define BUClient_BUCModels_h

@interface BUCPost : NSObject <NSLayoutManagerDelegate>

@property (nonatomic) NSAttributedString *forumName;
@property (nonatomic) NSString *fid;
@property (nonatomic) NSString *tid;
@property (nonatomic) NSString *pid;
@property (nonatomic) NSString *user;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSString *date;
@property (nonatomic) NSURL *avatarUrl;
@property (nonatomic) UIImage *avatar;
@property (nonatomic) NSString *title;

@property (nonatomic) NSUInteger index;
@property (nonatomic) CGFloat cellHeight;
@property (nonatomic) CGRect textFrame;

@property (nonatomic) BOOL bookmarked;
@property (nonatomic) NSInteger bookmarkIndex;

@property (nonatomic) NSAttributedString *content;
@property (nonatomic) NSAttributedString *meta;

@property (nonatomic) NSTextStorage *textStorage;
@property (nonatomic) BUCLayoutManager *layoutManager;
@property (nonatomic) BUCTextContainer *textContainer;
@property (nonatomic) UIImage *contents;

- (instancetype)initWithTextStack;

@end


@interface BUCImageAttachment : NSTextAttachment

@property (nonatomic) NSUInteger glyphIndex;
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *path;

@end


typedef NS_OPTIONS(uint32_t, BUCLinkType) {
    BUCPostLink = 1 << 0,
    BUCMailLink = 1 << 1,
    BUCUrlLink = 1 << 2
};


@interface BUCLinkAttribute : NSObject

@property (nonatomic) BUCLinkType linkType;
@property (nonatomic) NSString *linkValue;
@property (nonatomic) NSRange range;

@end


@interface BUCTextBlockAttribute : NSObject

@property (nonatomic) CGFloat padding;
@property (nonatomic) NSRange range;

@property (nonatomic) UIColor *backgroundColor;

@property (nonatomic) BOOL noBackground;

@end


#endif



























