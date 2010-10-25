//
//  Hoccer.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
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
	
	id <HCLinccerDelegate> delegate;
}

@property (retain) HCEnvironmentManager* environmentController;
@property (assign) id <HCLinccerDelegate> delegate;
@property (assign) BOOL isRegistered;

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret;  
- (void)send: (NSDictionary *)data withMode: (NSString *)mode;
- (void)receiveWithMode: (NSString *)mode;
- (void)disconnect;

@end
