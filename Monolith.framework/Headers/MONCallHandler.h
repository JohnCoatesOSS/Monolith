//
//  MONCallHandler.h
//  Monolith
//
//  Created by John Coates on 4/21/15.
//  Copyright (c) 2015 John Coates. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MONCallHandler : NSObject

@property (readonly) id instance;
@property (readonly) SEL selector;
@property MNOHook *hook;

- (instancetype)initWithInstance:(id)instance selector:(SEL)selector stackPointer:(void *)stackPointer;
- (instancetype)initWithClass:(Class)echelon selector:(SEL)selector stackPointer:(void *)stackPointer;

/// Calls original method and returns an NSObject encapsulating the return value
- (id)callOriginalMethod;

@end


@interface MONCallHandler (Setters)

- (BOOL)setArgument:(NSUInteger)argumentIndex toValue:(id)object;

@end
