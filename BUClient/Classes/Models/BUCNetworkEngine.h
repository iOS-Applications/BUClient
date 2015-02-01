#import "BUCConstants.h"


@interface BUCNetworkEngine : NSObject

@property (readonly, nonatomic) NSString *host;

- (void)fetchJSONFromAPI:(NSString *)api
                    JSON:(NSDictionary *)json
              attachment:(UIImage *)attachment
                  isForm:(BOOL)isForm
                 onError:(BUCStringBlock)errorBlock
               onSuccess:(BUCMapBlock)mapBlock;


- (void)fetchDataFromURL:(NSURL *)url
                 onError:(BUCStringBlock)errorBlock
               onSuccess:(BUCDataBlock)dataBlock;

@end
