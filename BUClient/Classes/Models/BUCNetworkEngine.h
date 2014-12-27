#import "BUCConstants.h"


@interface BUCNetworkEngine : NSObject


- (void)fetchJsonFromUrl:(NSString *)url
                    json:(NSDictionary *)json
              attachment:(UIImage *)attachment
                  isForm:(BOOL)isForm
                onResult:(BUCMapBlock)mapBlock
                 onError:(BUCStringBlock)errorBlock;

- (void)fetchDataFromUrl:(NSURLRequest *)request
                onResult:(BUCDataBlock)dataBlock
                 onError:(BUCStringBlock)errorBlock;


@end
