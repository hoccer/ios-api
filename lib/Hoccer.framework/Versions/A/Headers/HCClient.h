//
//  Hoccer.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCClientDelegate.h"
#import "HCEnvironmentManagerDelegate.h"

#define HoccerError @"HoccerError"

#define HCTransferModeOneToOne @"pass"
#define HCTransferModeOneToMany @"distribute"

enum HoccerErrors {
	HoccerNoReceiverError = 1,
	HoccerNoSenderError
};

@class HttpClient;

@interface HCClient : NSObject <HCEnvironmentManagerDelegate> {
	@private
	HCEnvironmentManager *environmentController;
	HttpClient *httpClient;

	NSString *uri;
	BOOL isRegistered;
	
	id <HCClientDelegate> delegate;
}

@property (retain) HCEnvironmentManager* environmentController;
@property (assign) id <HCClientDelegate> delegate;
@property (assign) BOOL isRegistered;

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret;  
- (void)send: (NSDictionary *)data withMode: (NSString *)mode;
- (void)receiveWithMode: (NSString *)mode;
- (void)disconnect;

@end
