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

@class HttpClient;

@interface Hoccer : NSObject <LocationControllerDelegate> {
	@private
	LocationController *environmentController;
	HttpClient *httpClient;

	NSString *uri;
	BOOL isRegistered;
	
	id <HoccerDelegate> delegate;
}

@property (assign) id <HoccerDelegate> delegate;
@property (assign) BOOL isRegistered;

- (void)send: (NSData *)data withMode: (NSString *)mode;
- (void)receiveWithMode: (NSString *)mode;

- (void)peek;

- (void)disconnect;

@end
