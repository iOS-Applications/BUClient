//
//  BUCHTMLParser.h
//  BUClient
//
//  Created by Joe Jeong on 2/18/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BUCHTMLParser : NSObject
+ (BUCHTMLParser *)sharedInstance;
- (NSString *)parse:(NSString *)html;
@end
