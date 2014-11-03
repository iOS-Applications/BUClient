//
//  BUCPostFragment.h
//  BUClient
//
//  Created by Joe Jeong on 11/1/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BUCPostFragment : NSObject

@property (nonatomic) NSMutableAttributedString *richText;
@property (nonatomic) NSString *imageURL;

@property (nonatomic) NSArray *children;

@property (nonatomic) BOOL isRichText;
@property (nonatomic) BOOL isBlock;
@property (nonatomic) BOOL isImage;

@end
