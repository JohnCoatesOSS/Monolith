//
//  TWEView.m
//  Monolith Tweak
//
//  Why the TWE prefix? It stands for Tweak.
//  Please use your own three letter prefix, or your tweak will conflict with others.

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

+ (BOOL)shouldAutomaticallyInstallHooks {
    // Only load into our test target
    MONProcess *process = [MONProcess currentProcess];
    NSString *bundleIdentifier = [process bundleIdentifier];
    
    if ([bundleIdentifier isEqualToString:@"com.monolith.Target"]) {
        return YES;
    }
    else {
        return NO;
    }
}

@end