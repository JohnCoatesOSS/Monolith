//
//  OBJCPluginExample.m
//  ObjectiveC Tweak
//
//  Created by John Coates on 6/8/15.
//  Copyright (c) 2015 John Coates. All rights reserved.
//

#import "MonolithPluginName.h"

@implementation MonolithPluginName

+ (void)load {
    NSLog(@"Monolith Plugin: %@ running!", [self name]);
}

+ (NSString *)name {
	return @"Monolith Plugin Example";
}

+ (BOOL)shouldLoadIntoProcess:(MONProcess *)process {
	return YES; // Load into every process
	
}

@end
