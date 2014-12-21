#import <Foundation/Foundation.h>
#import "BUCDataManager.h"
#import "BUCModels.h"

@interface BUCHTMLScraper : NSObject

@property (nonatomic) BUCDataManager *dataManager;

- (BUCRichText *)richTextFromHtml:(NSString *)html;
- (BUCRichText *)richTextFromHtml:(NSString *)html attributes:(NSDictionary *)attributes;
- (BUCRichText *)richTextFromHtml:(NSString *)html textStyle:(NSString *)style;
- (BUCRichText *)richTextFromHtml:(NSString *)html textStyle:(NSString *)style trait:(uint32_t)trait;

- (NSURL *)avatarUrlFromHtml:(NSString *)html;

@end
