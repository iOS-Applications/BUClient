#import <Foundation/Foundation.h>

#import "BUCAuthManager.h"
#import "BUCImageManager.h"
#import "BUCConstants.h"


@interface BUCDataManager : NSObject


@property (nonatomic, readonly) BUCAuthManager *authManager;
@property (nonatomic, readonly) BUCImageManager *imageManager;

+ (BUCDataManager *)sharedInstance;


- (void)listOfFrontOnSuccess:(BUCListBlock)listBlock onError:(BUCErrorBlock)errorBlock;

- (void)listOfForum:(NSString *)fid
                from:(NSString *)from
                  to:(NSString *)to
           onSuccess:(BUCListBlock)listBlock
             onError:(BUCErrorBlock)errorBlock;

- (void)listOfPost:(NSString *)postID
           from:(NSString *)from
             to:(NSString *)to
      onSuccess:(BUCListBlock)listBlock
        onError:(BUCErrorBlock)errorBlock;

- (void)childCountOfForum:(NSString *)fid post:(NSString *)pid onSuccess:(BUCNumberBlock)numberBlock onError:(BUCErrorBlock)errorBlock;

- (void)getImageFromUrl:(NSURL *)url onSuccess:(BUCImageBlock)imageBlock;

- (void)getImageFromUrl:(NSURL *)url size:(CGSize)size onSuccess:(BUCImageBlock)imageBlock;

@end
