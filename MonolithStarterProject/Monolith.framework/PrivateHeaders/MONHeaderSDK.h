//
//  MONHeaderSDK.h
//  Monolith
//
//  Created by John Coates on 3/18/16.
//  Copyright © 2016 John Coates. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MONHeaderSDK : NSObject

@property NSDictionary *interfaces;
@property NSDictionary *categories;
@property NSDictionary *protocols;
@property NSDictionary *types;
@property NSDictionary *typeDefs;

- (instancetype)initWithFilePath:(NSString *)filePath;

@end
