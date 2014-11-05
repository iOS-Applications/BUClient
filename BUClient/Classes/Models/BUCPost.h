#import <Foundation/Foundation.h>
#import "BUCPostFragment.h"


@interface BUCPost : NSObject


@property (nonatomic) BUCPost *parent;
@property (nonatomic) BUCPost *lastReply;

@property (nonatomic) NSString *pid;
@property (nonatomic) NSString *fid;
@property (nonatomic) NSAttributedString *fname;

@property (nonatomic) NSAttributedString *user;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSString *avatar;

@property (nonatomic) NSAttributedString *title;
@property (nonatomic) NSArray *fragments; // contains array of content fragments
@property (nonatomic) NSString *dateline;

@property (nonatomic) NSString *childCount;

@property (nonatomic) NSInteger index;


@end
