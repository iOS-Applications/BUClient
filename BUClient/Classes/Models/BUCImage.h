#import <Foundation/Foundation.h>


@interface BUCImage : NSObject


@property (nonatomic) UIImage *image;
@property (nonatomic) CGRect bounds;
@property (nonatomic) NSUInteger glyphIndex;
@property (nonatomic) NSURL *url;
@property (nonatomic) BOOL isGif;


@end
