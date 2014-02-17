//
//  BUCPoster.h
//  BUClient
//
//  Created by Joe Jeong on 2/14/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BUCPoster : NSObject
@property (nonatomic) NSData *avatar;
@property (nonatomic) NSString *avatarUrl;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *credit;

// temporary solution, since current buapi has some design issues.
// these properties will be removed once buapi is more sophisticated, well, I hope so
@property (nonatomic) NSDictionary *jsonData;
@end
