#ifndef BUClient_BUCConstants_h
#define BUClient_BUCConstants_h


// user default keys
extern NSString * const BUCAppLaunchStateDefaultKey;
extern NSString * const BUCCurrentUserDefaultKey;
extern NSString * const BUCUserLoginStateDefaultKey;

// name of main storyboard file
extern NSString * const BUCMainStoryboardPath;

// storyboard identifier of controllers
extern NSString * const BUCLoginControllerStoryboardID;
extern NSString * const BUCRootControllerStoryboardID;
extern NSString * const BUCContentControllerStoryboardID;
extern NSString * const BUCPostListControllerStoryboardID;
extern NSString * const BUCPostDetailControllerStoryboardID;

// storyboard identifier of segues
extern NSString * const BUCUnwindToRootStoryboardID;

// geometry constants
extern CGFloat const BUCImageThumbnailWidth;
extern CGFloat const BUCImageThumbnailHeight;


// rich text attirbute keys
extern NSString * const BUCLinkAttributeName;
extern NSString * const BUCTextBlockAttributeName;
extern NSString * const BUCAttachmentListAttributeName;
extern NSString * const BUCTextBlockListAttributeName;

// link types
typedef NS_OPTIONS(uint32_t, BUCLinkType) {
    BUCHomeLink = 1 << 0,
    BUCForumListLink = 1 << 1,
    BUCForumLink = 1 << 2,
    BUCPostLink = 1 << 3,
    BUCUserLink = 1 << 4,
    
    BUCMailLink = 1 << 5,
    BUCUrlLink = 1 << 6
};


#endif




