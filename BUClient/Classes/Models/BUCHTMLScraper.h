#import <Foundation/Foundation.h>


@interface BUCHTMLScraper : NSObject


- (NSAttributedString *)richTextFromHtml:(NSString *)html;

- (NSURL *)avatarUrlFromHtml:(NSString *)html;


@end
