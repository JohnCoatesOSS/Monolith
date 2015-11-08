//
//  MONTalkDaemon.h
//  Monolith
//
//  Created by John Coates on 6/10/15.
//  Copyright (c) 2015 John Coates. All rights reserved.
//


/**
	MONTalkDaemon is an abstract class for communicating with other processes.
	It will be automatically loaded into the Monolith daemon, monolithd.
	Because monolithd is loaded as root, this daemon has access to the complete filesystem.
 
	Safety:
	Many times these sorts of daemons are loaded into SpringBoard, but that can lead to
	re-spring loops. Instead, becaue this is loaded into monolithd, a bug in your code
	will lead to a crash that doesn't affect system stability.
 
	### Subclassing Notes
	

 */

@interface MONTalkDaemon : NSObject

// The server identifier for your daemon. You're required to subclass this.
+ (NSString *)serverIdentifier;

/// This method is called after your subclass is automatically instantiated into monolithd
/// Use this method instead of overriding init
- (void)loadedIntoDaemon;

- (void)registerForMessageName:(NSString *)messageName selector:(SEL)selector;

- (void)registerForMessages;

+ (NSDictionary *)sendWithReply:(NSString *)messageName attachment:(NSDictionary *)attachment error:(NSError **)error;

@end
