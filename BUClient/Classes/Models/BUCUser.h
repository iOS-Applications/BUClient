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
@property BOOL loginSuccess;

@property (nonatomic, strong) NSMutableDictionary *keychainData;
@property (nonatomic, strong) NSMutableDictionary *genericPasswordQuery;

+ (BUCUser *)sharedInstance;

- (BOOL)loginForLaunch;
- (void)loginCompletionHandler:(void (^)(NSString *errorMessage))completionHandler;
- (void)cancelLogin;
- (void)setNewPassword:(NSString *)newPassword;

@end
