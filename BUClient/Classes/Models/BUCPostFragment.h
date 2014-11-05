#import <Foundation/Foundation.h>


@interface BUCPostFragment : NSObject


@property (nonatomic) NSMutableAttributedString *richText;
@property (nonatomic) NSString *imageURL;

@property (nonatomic) NSArray *children;

@property (nonatomic) BOOL isRichText;
@property (nonatomic) BOOL isBlock;
@property (nonatomic) BOOL isImage;
@property (nonatomic) BOOL isCode;


@end
