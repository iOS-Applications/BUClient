#import <Foundation/Foundation.h>


@interface BUCHTMLScraper : NSObject


- (NSArray *)fragmentsFromHTML:(NSString *)html;

- (NSAttributedString *)titleFromHTML:(NSString *)html;

- (NSURL *)avatarUrlFromHtml:(NSString *)html;


@end
