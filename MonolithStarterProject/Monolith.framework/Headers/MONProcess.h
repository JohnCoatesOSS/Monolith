//
//  MONProcess.h
//  Monolith
//
//  Created by John Coates on 6/4/15.
//  Copyright (c) 2015 John Coates. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MONProcess : NSObject <NSCoding>

@property (readonly) NSString *bundleIdentifier;
@property (readonly) NSString *executablePath;
@property (readonly, nonatomic) BOOL isBlacklisted;
@property (readonly) NSNumber *processID;

/// Whether process is being debugged
@property (readonly, nonatomic) BOOL isBeingDebugged;

+ (instancetype)currentProcess;

- (BOOL)isSpringBoard;
/// Whether we're running in OS X
- (BOOL)isOSX;
/// Whether we're running in the iOS simulator
- (BOOL)isSimulator;

/// Whether this process is the Monolith daemon
/// This is where all daemon components get loaded.
- (BOOL)isMonolithDaemon;

@end
