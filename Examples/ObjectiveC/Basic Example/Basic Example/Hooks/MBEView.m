//
//  MBEView.m
//  Basic Example
//
//  Created by John Coates on 4/28/15.
//  Copyright (c) 2015 John Coates. All rights reserved.
//

#import "MBEView.h"

@implementation MBEView

+ (NSArray *)targetClasses {
    return @[@"UIView"];
}

- (void)setBackgroundColor:(UIColor *)color hook:(MONCallHandler *)callHandler {
    [callHandler setArgument:2 toValue:[UIColor greenColor]];
    [callHandler callOriginalMethod];
}

@end
