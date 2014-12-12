#import <Foundation/Foundation.h>
#import "BUCConstants.h"


@interface BUCDataManager : NSObject


@property (nonatomic, readonly) BOOL loggedIn;


+ (BUCDataManager *)sharedInstance;


- (void)loginWithUsername:(NSString *)username password:(NSString *)password onSuccess:(BUCVoidBlock)voidBlock onFail:(BUCErrorBlock)errorBlock;

- (void)logOut;

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

- (void)childCountOfForum:(NSString *)fid thread:(NSString *)tid onSuccess:(BUCNumberBlock)numberBlock onError:(BUCErrorBlock)errorBlock;

- (void)getImageWithUrl:(NSURL *)url size:(CGSize)size onSuccess:(BUCImageBlock)imageBlock;

- (UIImage *)getImageWithPath:(NSString *)path;

- (void)newPostToForum:(NSString *)fid thread:(NSString *)tid subject:(NSString *)subject content:(NSString *)content attachment:(UIImage *)attachment onSuccess:(BUCStringBlock)stringBlock onError:(BUCErrorBlock)errorBlock;

@end
