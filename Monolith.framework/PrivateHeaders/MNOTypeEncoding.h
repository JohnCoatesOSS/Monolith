//
//  MNOTypeEncoding.h
//  Flexapp
//
//  Created by John Coates on 7/23/14.
//  Copyright (c) 2014 John Coates. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@class MNOTypeEncodingItem;
@interface MNOTypeEncoding : NSObject

@property (readonly, nonatomic) MNOTypeEncodingItem *returnType;
@property (readonly, nonatomic) NSArray *arguments;
@property (readonly, nonatomic) NSUInteger argumentsBytes;
@property (readonly, nonatomic) int sizeInBytes;

// init
- (instancetype)initWithMethod:(Method)method;
- (instancetype)initWithTypeEncoding:(const char *)typeEncoding;

@end

#import "MNOTypeEncoding+Formatting.h"