//
//  BUCUser.h
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BUCUser : NSObject

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *session;
@property (nonatomic) NSMutableDictionary *json;
@property (nonatomic) NSURLRequest *req;
@property (nonatomic) BOOL isLoggedIn;
@property (nonatomic) NSString *loadImage;

+ (BUCUser *)sharedInstance;

- (void)setNewPassword:(NSString *)newPassword;
- (NSString *)getPassword;

@end
