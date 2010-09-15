//
//  Hoccer.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCClientDelegate.h"
#import "LocationControllerDelegate.h"

#define HoccerError @"HoccerError"

enum HoccerErrors {
	HoccerNoReceiverError = 1,
	HoccerNoSenderError
};



@class HttpClient;

@interface HCClient : NSObject <LocationControllerDelegate> {
	@private
	LocationController *environmentController;
	HttpClient *httpClient;

	NSString *uri;
	BOOL isRegistered;
	
	id <HCClientDelegate> delegate;
}

@property (retain) LocationController* environmentController;
@property (assign) id <HCClientDelegate> delegate;
@property (assign) BOOL isRegistered;

- (void)send: (NSData *)data withMode: (NSString *)mode;
- (void)receiveWithMode: (NSString *)mode;
- (void)disconnect;

@end
