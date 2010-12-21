//
//  Hoccer.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCLinccerDelegate.h"
#import "HCEnvironmentManagerDelegate.h"
#import "HCAuthenticatedHttpClient.h"

#define HoccerError @"HoccerError"

#define HCTransferModeOneToOne @"one-to-one"
#define HCTransferModeOneToMany @"one-to-many"

enum HoccerErrors {
	HoccerNoReceiverError = 1,
	HoccerNoSenderError
};

@class HttpClient;

@interface HCLinccer : NSObject <HCEnvironmentManagerDelegate> {
	@private
	HCEnvironmentManager *environmentController;
	HCAuthenticatedHttpClient *httpClient;

	NSString *uri;
	BOOL isRegistered;
	
	NSTimer *updateTimer;
	
	id <HCLinccerDelegate> delegate;
}

@property (retain) HCEnvironmentManager* environmentController;
@property (assign) id <HCLinccerDelegate> delegate;
@property (assign) BOOL isRegistered;

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret;
- (id) initWithApiKey:(NSString *)key secret:(NSString *)secret sandboxed: (BOOL)sandbox;

- (void)send: (NSDictionary *)data withMode: (NSString *)mode;
- (void)receiveWithMode: (NSString *)mode;

- (void)reactivate;
- (void)disconnect;

@end
