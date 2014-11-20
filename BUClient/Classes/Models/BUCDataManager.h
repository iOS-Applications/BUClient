#import <Foundation/Foundation.h>


typedef void(^ArrayBlock) (NSArray *list);
typedef void(^ErrorBlock) (NSError *error);
typedef void(^SuccessBlock) (NSDictionary *json);
typedef void(^ImageBlock) (UIImage *image);


@interface BUCDataManager : NSObject


+ (BUCDataManager *)sharedInstance;

- (void)getFrontListOnSuccess:(ArrayBlock)arrayBlock onError:(ErrorBlock)errorBlock;

- (void)getForumList:(NSString *)fid
                from:(NSString *)from
                  to:(NSString *)to
           OnSuccess:(ArrayBlock)arrayBlock
             onError:(ErrorBlock)errorBlock;

- (void)getPost:(NSString *)postID
           from:(NSString *)from
             to:(NSString *)to
      onSuccess:(ArrayBlock)arrayBlock
        onError:(ErrorBlock)errorBlock;

- (void)getImageFromUrl:(NSURL *)url onSuccess:(ImageBlock)imageBlock;

@end
