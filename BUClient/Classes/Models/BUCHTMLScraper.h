#import <Foundation/Foundation.h>
#import "BUCDataManager.h"


@interface BUCHTMLScraper : NSObject

@property (nonatomic, weak) BUCDataManager *dataManager;

- (NSAttributedString *)richTextFromHtml:(NSString *)html;

- (NSURL *)avatarUrlFromHtml:(NSString *)html;


@end
