//
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
    // Only load into our target
    if ([[process bundleIdentifier] isEqualToString:@"com.monolith.Target"]) {
        return YES;
    }
    else {
        return NO;
    }
}

@end
