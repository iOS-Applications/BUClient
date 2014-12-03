#import <Foundation/Foundation.h>
#import "BUCConstants.h"


@interface BUCNetworkEngine : NSObject


- (void)fetchJsonFromUrl:(NSString *)url
                    json:(NSDictionary *)json
                onResult:(BUCMapBlock)mapBlock
                 onError:(BUCErrorBlock)errorBlock;

- (void)fetchDataFromUrl:(NSURLRequest *)request onResult:(BUCDataBlock)dataBlock onError:(BUCErrorBlock)errorBlock;


@end
