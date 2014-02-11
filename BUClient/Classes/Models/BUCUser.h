//
//  BUCUser.h
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BUCUser : NSObject

@property NSString *username;
@property NSString *password;
@property NSString *session;
@property NSMutableDictionary *loginDic;
@property NSMutableDictionary *loginDataDic;
@property BOOL isLoggedIn;
@property NSString *loadImage;

+ (BUCUser *)sharedInstance;

- (void)setNewPassword:(NSString *)newPassword;
- (NSString *)getPassword;

@end
