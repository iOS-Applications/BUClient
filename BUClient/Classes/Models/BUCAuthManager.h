#import <Foundation/Foundation.h>


typedef void(^AuthSuccessBlock) (void);
typedef void(^AuthFailBlock) (NSError *);
typedef void(^AuthSessionBlock) (void);


@interface BUCAuthManager : NSObject


@property (nonatomic, readonly) NSString *currentUser;
@property (nonatomic, readonly) NSString *session;


+ (BUCAuthManager *)sharedInstance;

- (void)loginWithUsername:(NSString *)username
              andPassword:(NSString *)password
                onSuccess:(AuthSuccessBlock)successBlock
                   onFail:(AuthFailBlock)failBlock;

- (void)updateSessionOnSuccess:(AuthSessionBlock)sessionBlock onFail:(AuthFailBlock)failBlock;


@end