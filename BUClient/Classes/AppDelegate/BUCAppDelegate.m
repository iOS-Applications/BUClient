#import "BUCAppDelegate.h"
#import "BUCConstants.h"

@implementation BUCAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:BUCAppLaunchStateDefaultKey];
}

@end





















