#import <Foundation/Foundation.h>
#import "BUCDataManager.h"


@interface BUCHTMLScraper : NSObject

@property (nonatomic, weak) BUCDataManager *dataManager;

- (NSAttributedString *)richTextFromHtml:(NSString *)html;
- (NSAttributedString *)richTextFromHtml:(NSString *)html attributes:(NSDictionary *)attributes;
- (NSAttributedString *)richTextFromHtml:(NSString *)html textStyle:(NSString *)style;
- (NSAttributedString *)richTextFromHtml:(NSString *)html textStyle:(NSString *)style trait:(uint32_t)trait;

- (NSURL *)avatarUrlFromHtml:(NSString *)html;

@end
