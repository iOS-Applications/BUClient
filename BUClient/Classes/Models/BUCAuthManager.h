#import <Foundation/Foundation.h>


typedef void(^AuthSuccessBlock) (void);
typedef void(^AuthFailBlock) (NSError *);

@interface BUCAuthManager : NSObject


@property (nonatomic, readonly) NSString *currentUser;
@property (nonatomic, readonly) NSString *session;


+ (instancetype)sharedInstance;

- (void)loginWithUsername:(NSString *)username
              password:(NSString *)password
                onSuccess:(AuthSuccessBlock)successBlock
                   onFail:(AuthFailBlock)failBlock;

- (void)updateSessionOnSuccess:(AuthSuccessBlock)sessionBlock onFail:(AuthFailBlock)failBlock;


@end
