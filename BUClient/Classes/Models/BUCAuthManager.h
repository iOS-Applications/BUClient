#import <Foundation/Foundation.h>


@interface BUCAuthManager : NSObject

- (NSString *)getPasswordWithUsername:(NSString *)username;
- (void)savePassword:(NSString *)password username:(NSString *)username;

@end
