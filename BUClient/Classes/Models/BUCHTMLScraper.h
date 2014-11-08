#import <Foundation/Foundation.h>


@interface BUCHTMLScraper : NSObject


- (NSArray *)fragmentsFromHTML:(NSString *)html;

- (NSAttributedString *)titleFromHTML:(NSString *)html;

- (NSString *)imageURLFromHTML:(NSString *)html;


@end
