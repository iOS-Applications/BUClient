#import "BUCPostFragment.h"


@implementation BUCPostFragment


- (void)addImage:(id)image
{
    if (self.imageArray) {
        [self.imageArray addObject:image];
    } else {
        self.imageArray = [[NSMutableArray alloc] initWithObjects:image, nil];
    }
}


@end
