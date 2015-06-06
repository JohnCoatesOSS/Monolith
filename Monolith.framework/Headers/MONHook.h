//
//  MONHook.h
//  Monolith
//
//  Created by John Coates on 5/29/14.
//  Copyright (c) 2014 John Coates. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 MONHook is an abstract class used for hooking other classes. Because it is an abstract
 class, you do not use this class directly but instead subclass it to perform the actual hooking.
 Even though it is an abstract class, the default implementation of MONHook includes a signficiant
 amount of logic to safely process your hooks.

### Subclassing Notes
 
You must subclass + (NSString *)targetClass;

## How To Hook a Class
 
If your target method is:

@code
- (BOOL)shouldPlayInline;
@endcode
 
Your hook would look like this:

@code
- (BOOL)shouldPlayInline_hook:(MONCallHandler *)call {
	NSNumber *originalReturnValue = [call callOriginalMethod];
	NSLog(@"[%@ %@] originally returned: %@, replacing return value with TRUE",
		NSStringFromClass([self class]),
		NSStringFromSelector(_cmd),
		originalReturnValue
		);
 
	return TRUE;
}
@endcode
 
*/
@interface MONHook : NSObject

/** @name Required Subclassing */

/**
 *  This method must be subclassesd.
 *
 *  @warning `targetClass` must not return `nil`.
 *  @return The class name you're attempting to override.
 */
+ (NSString *)targetClass;


/**
	Whether hooks should be automatically installed.

	This is the preferred way to handle hooks. A manual hooking method will be added in the future.
	@return Whether this class should automatically install hooks on load. Defaults to YES
 */
+ (BOOL)shouldAutomaticallyInstallHooks;

/**
	When this method is subclasses it will be called to notify a class
	that its hooks have been installed.
*/

+ (void)installedHooks;
@end
