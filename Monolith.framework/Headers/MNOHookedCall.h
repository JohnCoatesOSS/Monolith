//
//  MNOHookedCall.h
//  AssistantLove2
//
//  Created by John Coates on 5/29/14.
//  Copyright (c) 2014 John Coates. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MNOHook;

@interface MNOHookedCall : NSObject

@property MNOHook *hook;

/// Whether the original method should be called after the hook method returns.
@property BOOL shouldCallOriginalMethod;

@property (readonly) id instance;
@property (readonly) SEL selector;

- (instancetype)initWithInstance:(id)instance selector:(SEL)selector stackPointer:(void *)stackPointer;
- (id)getArgument:(NSUInteger)argument;
- (void)setReturnValue:(id)returnValue;

- (id)callOriginalMethod;

@end
