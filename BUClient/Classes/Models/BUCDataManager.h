#import <Foundation/Foundation.h>


typedef void(^ArrayBlock) (NSArray *);
typedef void(^ErrorBlock) (NSError *);
typedef void(^SuccessBlock) (NSDictionary *);
typedef void(^ImageBlock) (UIImage *);


@interface BUCDataManager : NSObject


+ (BUCDataManager *)sharedInstance;

- (void)getFrontListOnSuccess:(ArrayBlock)arrayBlock onError:(ErrorBlock)errorBlock;

- (void)getPost:(NSString *)postID
           from:(NSString *)from
             to:(NSString *)to
      onSuccess:(ArrayBlock)arrayBlock
        onError:(ErrorBlock)errorBlock;

- (void)getImageFromUrl:(NSString *)url onSuccess:(ImageBlock)imageBlock;

@end
