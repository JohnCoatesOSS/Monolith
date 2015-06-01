//
//  MNOHook.h
//  AssistantLove2
//
//  Created by John Coates on 5/29/14.
//  Copyright (c) 2014 John Coates. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
The MNOHook clas is an abstract class used for hooking other classes. Because it is an abstract
 class, you do not use this class directly but instead subclass it to perform the actual hooking.
 Even though it is an abstract class, the default implementation of MNOHook includes a signficiant
 amount of logic to safely process your hooks.

### Subclassing Notes
Notes go here

## Methods to Override
Abstract class blurb
 
*/
@interface MNOHook : NSObject

/** @name Required Subclassing */

/**
 *  This method must be subclassesd.
 *
 *  @warning `targetClass` must not return `nil`.
 *  @return The class name you're attempting to override.
 */
+ (NSString *)targetClass;


/** @name Manual Hooking */
/**
 Whether hooks should be automatically installed.

 This is the preferred way to handle hooks. Otherwise see
 
 *  @return Whether this class should automatically install hooks on load. Defaults to YES
 */
+ (BOOL)shouldAutomaticallyInstallHooks;

/**
When shouldAutomaticallyInstallHooks is set to FALSE this method can be used for manually
 installing hooks.
 
 Only attempts to hook as long as there's not an existing hook for this selector.
 
@param localSelector The selector from your subclass.

@return Returns whether selector hook was successful.
 */
//+ (BOOL)hookMethod:(SEL)localSelector;

@end
