#import <Foundation/Foundation.h>


typedef void(^networkResultBlock) (NSDictionary *);
typedef void(^networkErrorBlock) (NSError *);
typedef void(^networkImageBlock) (NSData *, NSURLResponse *);


@interface BUCNetworkEngine : NSObject


+ (BUCNetworkEngine *)sharedInstance;

- (void)fetchDataFromUrl:(NSString *)url
                    json:(NSDictionary *)json
                onResult:(networkResultBlock)resultBlock
                 onError:(networkErrorBlock)errorBlock;

- (void)fetchImageFromUrl:(NSURLRequest *)request onResult:(networkImageBlock)imageBlock onError:(networkErrorBlock)errorBlock;


@end
