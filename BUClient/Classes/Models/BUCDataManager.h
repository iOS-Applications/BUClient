#import "BUCConstants.h"


@interface BUCDataManager : NSObject

@property (nonatomic, readonly) NSString *host;;

@property (nonatomic, readonly) BOOL loggedIn;

@property (nonatomic, readonly) BOOL cancelFlag;


+ (BUCDataManager *)sharedInstance;


- (void)loginWithUsername:(NSString *)username password:(NSString *)password onSuccess:(BUCVoidBlock)voidBlock onFail:(BUCStringBlock)errorBlock;

- (void)logout;

- (void)listOfForum:(NSString *)fid
               from:(NSString *)from
                 to:(NSString *)to
          onSuccess:(BUCListBlock)listBlock
            onError:(BUCStringBlock)errorBlock;

- (void)listOfPost:(NSString *)postID
              from:(NSString *)from
                to:(NSString *)to
         onSuccess:(BUCListBlock)listBlock
           onError:(BUCStringBlock)errorBlock;

- (void)childCountOfForum:(NSString *)fid thread:(NSString *)tid onSuccess:(BUCNumberBlock)numberBlock onError:(BUCStringBlock)errorBlock;

- (void)getImageWithURL:(NSURL *)url size:(CGSize)size onSuccess:(BUCImageBlock)imageBlock;

- (UIImage *)getImageWithPath:(NSString *)path;

- (void)newPostToForum:(NSString *)fid thread:(NSString *)tid subject:(NSString *)subject content:(NSString *)content attachment:(UIImage *)attachment onSuccess:(BUCStringBlock)stringBlock onError:(BUCStringBlock)errorBlock;

- (void)resumeAllImageTasks;
- (void)cancelAllImageTasks;

- (BOOL)lookupBookmarkOfThread:(NSString *)tid;
- (void)bookmarkThread:(NSString *)tid title:(NSString *)title;
- (void)removeBookmarkOfThread:(NSString *)tid;
- (NSMutableArray *)getBookmarkList;
- (void)updateBookmarkList;

@end




