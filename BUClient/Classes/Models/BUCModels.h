#include "BUCTextStack.h"

#ifndef BUClient_BUCModels_h
#define BUClient_BUCModels_h


@interface BUCRichText : NSObject

@property (nonatomic) NSMutableAttributedString *richText;
@property (nonatomic) NSMutableArray *emotionList;
@property (nonatomic) NSMutableArray *imageList;
@property (nonatomic) NSMutableArray *blockList;

@end


@interface BUCImageAttachment : NSTextAttachment

@property (nonatomic) NSUInteger glyphIndex;
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *path;
@property (nonatomic) NSInteger tag;

@end


@interface BUCPost : NSObject <NSLayoutManagerDelegate>

@property (nonatomic) NSAttributedString *forumName;
@property (nonatomic) NSString *fid;
@property (nonatomic) NSString *tid;
@property (nonatomic) NSString *pid;
@property (nonatomic) NSString *user;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSString *date;
@property (nonatomic) BUCImageAttachment *avatar;
@property (nonatomic) NSString *title;

@property (nonatomic) NSUInteger index;
@property (nonatomic) CGFloat cellHeight;
@property (nonatomic) CGFloat cellWidth;
@property (nonatomic) CGRect bounds;

@property (nonatomic) BUCRichText *content;
@property (nonatomic) NSAttributedString *meta;

@property (nonatomic) NSTextStorage *textStorage;
@property (nonatomic) NSLayoutManager *layoutManager;
@property (nonatomic) BUCTextContainer *textContainer;

- (instancetype)initWithTextStack;

@end


typedef NS_OPTIONS(uint8_t, BUCLinkType) {
    BUCPostLink = 1 << 0,
    BUCUrlLink = 1 << 1
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



























