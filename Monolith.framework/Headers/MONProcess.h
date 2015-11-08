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

+ (instancetype)currentProcess;

- (BOOL)isSpringBoard;
- (BOOL)isSimulator;

/// Whether this process is the Monolith daemon
/// This is where all daemon components should get loaded.
- (BOOL)isMonolithDaemon;

@end
