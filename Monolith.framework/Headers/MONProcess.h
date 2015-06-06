//
//  MONProcess.h
//  Monolith
//
//  Created by John Coates on 6/4/15.
//  Copyright (c) 2015 John Coates. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MONProcess : NSObject

@property (readonly) NSString *bundleIdentifier;
@property (readonly) NSString *executablePath;

+ (instancetype)currentProcess;

- (BOOL)isSpringBoard;
- (BOOL)isSimulator;

@end
