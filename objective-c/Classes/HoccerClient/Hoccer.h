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

#define HoccerError @"HoccerError"

enum HoccerErrors {
	HoccerNobodyFound = 1
};



@class HttpClient;

@interface Hoccer : NSObject <LocationControllerDelegate> {
	@private
	LocationController *environmentController;
	HttpClient *httpClient;

	NSString *uri;
	BOOL isRegistered;
	
	id <HoccerDelegate> delegate;
}

@property (retain) LocationController* environmentController;
@property (assign) id <HoccerDelegate> delegate;
@property (assign) BOOL isRegistered;

- (void)send: (NSData *)data withMode: (NSString *)mode;
- (void)receiveWithMode: (NSString *)mode;

- (void)disconnect;

@end
