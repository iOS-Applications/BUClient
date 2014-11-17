#import <Foundation/Foundation.h>
#import "BUCConstants.h"

#ifndef BUClient_BUCModels_h
#define BUClient_BUCModels_h

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
@property (nonatomic) NSString *dateline;

@property (nonatomic) NSString *childCount;

@property (nonatomic) NSInteger index;

@end


@interface BUCImageAttachment : NSTextAttachment

@property (nonatomic) NSUInteger glyphIndex;
@property (nonatomic) NSURL *url;
@property (nonatomic) UIImage *gif;

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

@property (nonatomic) NSRange range;

@end


#endif



























