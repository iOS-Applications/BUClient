#import <Foundation/Foundation.h>


@interface BUCKeyChainWrapper : NSObject

- (NSString *)getPasswordWithUsername:(NSString *)username;
- (void)savePassword:(NSString *)password username:(NSString *)username;

@end
