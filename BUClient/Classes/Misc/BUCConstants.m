#import <Foundation/Foundation.h>

// user default keys
NSString * const BUCAppLaunchStateDefaultKey = @"AppIsJustLaunched";
NSString * const BUCCurrentUserDefaultKey = @"CurrentUser";
NSString * const BUCUserLoginStateDefaultKey = @"UserIsLoggedIn";

// name of main storyboard file
NSString * const BUCMainStoryboardPath = @"Main";

// storyboard identifier string of controllers
NSString * const BUCLoginControllerStoryboardID = @"BUCLoginController";
NSString * const BUCRootControllerStoryboardID = @"BUCRootController";
NSString * const BUCContentControllerStoryboardID = @"BUCContentController";
NSString * const BUCPostListControllerStoryboardID = @"BUCPostListController";
NSString * const BUCPostDetailControllerStoryboardID = @"BUCPostDetailController";

// storyboard identifier of segues
NSString * const BUCUnwindToRootStoryboardID = @"BUCUnwindToRoot";

// geometry constants
CGFloat const BUCImageThumbnailWidth = 310.0f;
CGFloat const BUCImageThumbnailHeight = 200.0f;


// BUC rich text attributes
NSString * const BUCLinkAttributeName = @"BUCLinkAttribute";
NSString * const BUCTextBlockAttributeName = @"BUCTextBlockAttribute";



