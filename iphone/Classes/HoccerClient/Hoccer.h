//
//  Hoccer.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HoccerDelegate.h"
#import "LocationControllerDelegate.h"

#import "HoccerRegister.h"

@interface Hoccer : NSObject <LocationControllerDelegate, HoccerRegisterDelegate> {
	LocationController *environmentController;
	NSString *uri;
	
	id <HoccerDelegate> delegate;
}

@property (assign) id <HoccerDelegate> delegate;

- (void)send: (NSData *)data withMode: (NSString *)mode;
- (void)receiveWithMode: (NSString *)mode;

- (void)peek;

- (void)disconnect;

@end
