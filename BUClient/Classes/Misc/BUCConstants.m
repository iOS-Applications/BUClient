#import <Foundation/Foundation.h>

// user default keys
NSString * const BUCAppLaunchStateDefaultKey = @"AppIsJustLaunched";
NSString * const BUCCurrentUserDefaultKey = @"CurrentUser";
NSString * const BUCUserLoginStateDefaultKey = @"UserIsLoggedIn";

// storyboard identifier string of controllers
NSString * const BUCLoginControllerStoryboardID = @"BUCLoginController";
NSString * const BUCRootControllerStoryboardID = @"BUCRootController";
NSString * const BUCContentControllerStoryboardID = @"BUCContentController";
NSString * const BUCPostListControllerStoryboardID = @"BUCPostListController";
NSString * const BUCPostDetailControllerStoryboardID = @"BUCPostDetailController";

// storyboard identifier of segues
NSString * const BUCUnwindToRootStoryboardID = @"BUCUnwindToRoot";

// geometry constants
CGFloat const BUCTopBarHeight = 64.0f;
CGFloat const BUCImageThumbnailHeight = 100.0f;

CGFloat const BUCDefaultPadding = 8.0f;
CGFloat const BUCDefaultMargin = 5.0f;

CGFloat const BUCBorderWidth = 0.5f;

// settings
int const BUCMaxImageCountSinglePost = 10;

// BUC rich text attributes
NSString * const BUCLinkAttributeName = @"BUCLinkAttribute";
NSString * const BUCTextBlockAttributeName = @"BUCTextBlockAttribute";
NSString * const BUCAttachmentListAttributeName = @"BUCAttachmentListAttribute";
NSString * const BUCTextBlockListAttributeName = @"BUCTextBlockListAttribute";


