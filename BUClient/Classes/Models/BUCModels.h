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
@property (nonatomic) NSString *postListDateline;

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
@property (nonatomic) NSString *path;

@end


typedef NS_OPTIONS(uint32_t, BUCLinkType) {
    BUCHomeLink = 1 << 0,
    BUCForumListLink = 1 << 1,
    BUCForumLink = 1 << 2,
    BUCPostLink = 1 << 3,
    BUCUserLink = 1 << 4,
    
    BUCMailLink = 1 << 5,
    BUCUrlLink = 1 << 6
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



























