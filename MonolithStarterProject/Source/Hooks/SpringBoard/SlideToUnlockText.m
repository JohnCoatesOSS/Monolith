//
//  SlideToUnlockText.m
//  Description: Changes the "Slide To Unlock" text on the lock screen.
//
//  Created by John Coates on 3/29/16.
//

#import "SlideToUnlockText.h"

@implementation SlideToUnlockText

+ (NSArray *)targetClasses {
    return @[@"SBLockScreenView"];
}

- (NSString *)_defaultSlideToUnlockText_hook:(MONCallHandler *)callHandler {
    return @"Monolith »";
}

@end
