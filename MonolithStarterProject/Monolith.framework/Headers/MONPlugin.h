//
//  MONPlugin.h
//  Monolith
//
//  Created by John Coates on 6/6/15.
//  Copyright (c) 2015 John Coates. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
	MONPlugin is an abstract class used to declare your plugin, use only once per plugin.
	Plugins that don't have a subclass of this won't be loaded.
 */

@interface MONPlugin : NSObject

/// Plugin name
+ (NSString *)name;

/// Called to ask if this plugin should be loaded into a process
+ (BOOL)shouldLoadIntoProcess:(MONProcess *)process;

@end
