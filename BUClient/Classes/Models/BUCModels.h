#import <Foundation/Foundation.h>
#import "BUCConstants.h"

#ifndef BUClient_BUCModels_h
#define BUClient_BUCModels_h

@interface BUCPost : NSObject

@property (nonatomic) NSString *pid;
@property (nonatomic) NSString *tid;
@property (nonatomic) NSString *fid;
@property (nonatomic) NSString *fname;

@property (nonatomic) NSString *user;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSURL *avatar;

@property (nonatomic) NSAttributedString *title;
@property (nonatomic) NSAttributedString *content;
@property (nonatomic) NSString *dateline;

@property (nonatomic) NSString *statistic;

@property (nonatomic) NSString *lastPostDateline;
@property (nonatomic) NSString *lastPoster;

@property (nonatomic) NSUInteger index;
@property (nonatomic) CGFloat cellHeight;
@property (nonatomic) CGRect textFrame;

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

@property (nonatomic) BOOL noBackground;

@end


#endif



























