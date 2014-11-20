#import <Foundation/Foundation.h>
#import "BUCConstants.h"

#ifndef BUClient_BUCModels_h
#define BUClient_BUCModels_h

@interface BUCPost : NSObject

@property (nonatomic) NSString *pid;
@property (nonatomic) NSString *fid;
@property (nonatomic) NSAttributedString *fname;

@property (nonatomic) NSAttributedString *user;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSURL *avatar;

@property (nonatomic) NSAttributedString *title;
@property (nonatomic) NSAttributedString *content;
@property (nonatomic) NSAttributedString *dateline;

@property (nonatomic) NSString *viewCount;
@property (nonatomic) NSString *childCount;

@property (nonatomic) NSInteger index;

@property (nonatomic) NSAttributedString *lastPostDateline;
@property (nonatomic) NSAttributedString *lastPoster;

@end


@interface BUCImageAttachment : NSTextAttachment

@property (nonatomic) NSUInteger glyphIndex;
@property (nonatomic) NSURL *url;
@property (nonatomic) UIImage *gif;

@end


@interface BUCLinkAttribute : NSObject

@property (nonatomic) BUCLinkType linkType;
@property (nonatomic) NSString *linkValue;
@property (nonatomic) NSRange range;

@end


@interface BUCTextBlockAttribute : NSObject

@property (nonatomic) CGFloat padding;
@property (nonatomic) NSRange range;

@property (nonatomic) UIColor *backgroundColor;

@end


#endif



























