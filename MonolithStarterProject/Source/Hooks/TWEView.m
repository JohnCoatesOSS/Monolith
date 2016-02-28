//
//  TWEView.m
//  ObjectiveC Tweak
//
//  Created by John Coates on 4/28/15.
//  Copyright (c) 2015 John Coates. All rights reserved.
//

#import "TWEView.h"

@implementation TWEView

+ (NSArray *)targetClasses {
    return @[@"UIView"];
}

- (void)setBackgroundColor:(UIColor *)color hook:(MONCallHandler *)callHandler {
	// set white background to something a little prettier
    CGFloat red, green, blue;
    [color getRed:&red green:&green blue:&blue alpha:nil];
	if (red == 1 && green == 1 & blue == 1) {
		[callHandler setArgument:2 toValue:[UIColor colorWithRed:0.6 green:0.36 blue:0.71 alpha:1]];
	}
	
	[callHandler callOriginalMethod];
}

@end