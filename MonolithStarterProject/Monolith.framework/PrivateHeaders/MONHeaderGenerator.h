//
//  MONHeaderGenerator.h
//  Monolith
//
//  Created by John Coates on 3/13/16.
//  Copyright © 2016 John Coates. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MONHeaderSDK;

@interface MONHeaderGenerator : NSObject

+ (instancetype)sharedInstance;

@property MONHeaderSDK *sdk;

+ (instancetype)generatorWithLatestSDK;

+ (NSString *)headerForClass:(Class)targetClass;

- (instancetype)initWithSDK:(MONHeaderSDK *)sdk;

@end
