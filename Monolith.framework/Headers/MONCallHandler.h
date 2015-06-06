//
//  MONCallHandler.h
//  Monolith
//
//  Created by John Coates on 4/21/15.
//  Copyright (c) 2015 John Coates. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MONCallHandler : NSObject

/// Calls original method and returns an NSObject encapsulating the return value
- (id)callOriginalMethod;

@end


@interface MONCallHandler (Setters)

/// Sets and argument before a call to -callOriginalMethod
/// Pass an NSObject encapsulating the original format.
- (BOOL)setArgument:(NSUInteger)argumentIndex toValue:(id)object;

@end
