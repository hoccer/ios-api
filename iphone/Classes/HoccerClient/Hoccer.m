//
//  Hoccer.m
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "Hoccer.h"
#import "LocationController.h"
#import "HoccerRegister.h"


@implementation Hoccer
@synthesize delegate;

- (id) init {
	self = [super init];
	if (self != nil) {
		environmentController = [[LocationController alloc] init];
		environmentController.delegate = self;
		
		
		HoccerRegister *registerClient = [[HoccerRegister alloc] init];
		registerClient.delegate = self;
		
		// get id (from prefs or create new on server
	}
	return self;
}

- (void)send: (NSData *)data withMode: (NSString *)mode {
}

- (void)receiveWithMode: (NSString *)mode {
}

- (void)peek {
}

#pragma mark -
#pragma mark HoccerRegister Delegate Methods 
- (void)hoccer: (HoccerRegister *)request didRegisterWithInfo: (NSDictionary *)info {
	NSLog(@"url: %@", [info objectForKey:@"uri"]);
	uri = [[info objectForKey:@"uri"] copy];
}

#pragma mark -
#pragma mark didReceiveInfo




#pragma mark -
#pragma mark LocationController Delegate Methods

- (void) locationControllerDidUpdateLocation: (LocationController *)controller {
	NSLog(@"environment: %@", [controller.location JSONRepresentation]);
	// NSLog(@"send environment to : %@/environment", uri);
}

- (void)disconnect {
	
}


- (void)dealloc {
    [super dealloc];
}


@end
