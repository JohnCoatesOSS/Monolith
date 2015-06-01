//
//  MBEView.m
//  Basic Example
//
//  Created by John Coates on 4/28/15.
//  Copyright (c) 2015 John Coates. All rights reserved.
//

#import "MBEView.h"

@implementation MBEView

+ (NSString *)targetClass {
    return @"UIView";
}

- (UIColor *)backgroundColor_hook:(MONCallHandler *)callHandler {
    return [UIColor greenColor];
}

@end
