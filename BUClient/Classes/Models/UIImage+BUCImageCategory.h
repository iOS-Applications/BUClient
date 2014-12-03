#import <Foundation/Foundation.h>


@interface UIImage (BUCImageCategory)
+ (UIImage *)imageWithData:(NSData *)data size:(CGSize)size;
@end