#import <Foundation/Foundation.h>


typedef void(^networkResultBlock) (NSDictionary *);
typedef void(^networkErrorBlock) (NSError *);
typedef void(^networkDataBlock) (NSData *);


@interface BUCNetworkEngine : NSObject


+ (BUCNetworkEngine *)sharedInstance;

- (void)fetchDataFromUrl:(NSString *)url
                    json:(NSDictionary *)json
                onResult:(networkResultBlock)resultBlock
                 onError:(networkErrorBlock)errorBlock;

- (void)fetchDataFromUrl:(NSURL *)url onResult:(networkDataBlock)dataBlock onError:(networkErrorBlock)errorBlock;


@end
