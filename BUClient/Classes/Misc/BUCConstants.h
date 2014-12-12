#ifndef BUClient_BUCConstants_h
#define BUClient_BUCConstants_h


// storyboard identifier of controllers
extern NSString * const BUCPostListControllerStoryboardID;

// global notifications
extern NSString * const BUCLoginStateNotification;

// user default keys
extern NSString * const BUCCurrentUserDefaultKey;
extern NSString * const BUCUserSignatureDefaultKey;
extern NSString * const BUCUserListDefaultKey;
extern NSString * const BUCUserNameDefaultKey;
extern NSString * const BUCUserPasswordDefaultKey;
extern NSString * const BUCUidDefaultKey;

// geometry constants
extern CGFloat const BUCDefaultPadding;
extern CGFloat const BUCDefaultMargin;
extern CGFloat const BUCBorderWidth;

// rich text attirbute keys
extern NSString * const BUCLinkAttributeName;
extern NSString * const BUCTextBlockAttributeName;
extern NSString * const BUCAttachmentListAttributeName;
extern NSString * const BUCTextBlockListAttributeName;


// block types
typedef void(^BUCMapBlock)(NSDictionary *map);
typedef void(^BUCListBlock)(NSArray *list);
typedef void(^BUCDataBlock)(NSData *data);
typedef void(^BUCImageBlock)(UIImage *image);
typedef void(^BUCNumberBlock)(NSUInteger number);
typedef void(^BUCErrorBlock)(NSError *error);
typedef void(^BUCStringBlock)(NSString *text);
typedef void(^BUCVoidBlock)(void);
#endif




