#import <Foundation/Foundation.h>
#import "BUCConstants.h"

#ifndef BUClient_BUCModels_h
#define BUClient_BUCModels_h

@interface BUCImageAttachment : NSTextAttachment

@property (nonatomic) NSUInteger glyphIndex;
@property (nonatomic) NSURL *url;

@end


@interface BUCRenderNode : NSObject

@property (nonatomic) NSTextStorage *textStorage;
@property (nonatomic) NSMutableAttributedString *richText;
@property (nonatomic) NSMutableArray *attachmentList;

@property (nonatomic) NSDictionary *attributes;

@property (nonatomic) NSMutableArray *children;
@property (nonatomic) BUCRenderNode *lastChild;
@property (nonatomic) BUCRenderNode *parent;

@property (nonatomic) BOOL isRichText;
@property (nonatomic) BOOL isBlock;

@property (nonatomic) BUCRenderNodeType nodeType;


- (instancetype)initWithRichText:(NSMutableAttributedString *)richText;
- (instancetype)initWithString:(NSString *)string;
- (instancetype)initWithAttachment:(BUCImageAttachment *)attachment;
- (void)addAttachment:(BUCImageAttachment *)attachment;
- (void)addChildNode:(BUCRenderNode *)child;


@end



@interface BUCPost : NSObject

@property (nonatomic) BUCPost *parent;
@property (nonatomic) BUCPost *lastReply;

@property (nonatomic) NSString *pid;
@property (nonatomic) NSString *fid;
@property (nonatomic) NSAttributedString *fname;

@property (nonatomic) NSAttributedString *user;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSURL *avatar;

@property (nonatomic) NSAttributedString *title;
@property (nonatomic) NSAttributedString *content;
@property (nonatomic) NSArray *fragments; // contains array of content fragments
@property (nonatomic) NSString *dateline;

@property (nonatomic) NSString *childCount;

@property (nonatomic) NSInteger index;

@end



@interface BUCLinkAttribute : NSObject

@property (nonatomic) BUCLinkType linkType;
@property (nonatomic) NSString *linkUrl;
@property (nonatomic) NSRange range;

@end


@interface BUCTextBlockAttribute : NSObject

@property (nonatomic) CGFloat topMargin;
@property (nonatomic) CGFloat leftMargin;

@property (nonatomic) CGFloat topPadding;
@property (nonatomic) CGFloat leftPadding;

@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) UIColor *borderColor;

@property (nonatomic) BOOL hasParent;

@end


#endif



























