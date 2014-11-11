#import <Foundation/Foundation.h>


@interface BUCPostFragment : NSObject


@property (nonatomic) NSMutableAttributedString *richText;
@property (nonatomic) NSMutableArray *imageArray;

@property (nonatomic) NSArray *children;

@property (nonatomic) BOOL isRichText;
@property (nonatomic) BOOL isBlock;


- (void)addImage:(id)image;


@end
