//
//  Monolith.h
//  Monolith
//
//  Created by John Coates on 7/25/14.
//  Copyright (c) 2014 John Coates. All rights reserved.
//

#import <TargetConditionals.h>
#import <Foundation/Foundation.h>

//! Project version number for Monolith.
FOUNDATION_EXPORT double MonolithVersionNumber;

//! Project version string for Monolith.
FOUNDATION_EXPORT const unsigned char MonolithVersionString[];

#import <Monolith/MONHook.h>
#import <Monolith/MONCallHandler.h>
#import <Monolith/MONProcess.h>
#import <Monolith/MONPlugin.h>

// Daemon
#import <Monolith/MONTalkDaemon.h>

// deprecated
#import <Monolith/MNOHook.h>