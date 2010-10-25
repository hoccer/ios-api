//
//  Hoccer.m
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <YAJLIOS/YAJLIOS.h>
#import "NSString+URLHelper.h"
#import "HCLinccer.h"
#import "HCEnvironmentManager.h"
#import "HCEnvironment.h"
#import "HttpClient.h"
#import "HCAuthenticatedHttpClient.h"

#define HOCCER_CLIENT_URI @"http://linker.beta.hoccer.com"
// #define HOCCER_CLIENT_URI @"http://192.168.2.101:9292"
#define HOCCER_CLIENT_ID_KEY @"hoccerClientUri" 


@interface HCLinccer ()

- (void)updateEnvironment;
- (void)didFailWithError: (NSError *)error;

- (NSDictionary *)userInfoForNoReceiver;
- (NSDictionary *)userInfoForNoSender;

- (NSString *)uuid;

@end

@implementation HCLinccer
@synthesize delegate;
@synthesize environmentController;
@synthesize isRegistered;

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret {
	self = [super init];
	if (self != nil) {
		environmentController = [[HCEnvironmentManager alloc] init];
		environmentController.delegate = self;

		httpClient = [[HCAuthenticatedHttpClient alloc] initWithURLString:HOCCER_CLIENT_URI];
		httpClient.apiKey = key;
		httpClient.secret = secret;
		httpClient.target = self;

		uri = [[@"/clients" stringByAppendingPathComponent:[self uuid]] retain];
		
		[self updateEnvironment];
	}
	
	return self;
}

- (void)send: (NSDictionary *)data withMode: (NSString *)mode {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	
	NSString *actionString = [@"/action" stringByAppendingPathComponent:mode];
	[httpClient putURI:[uri stringByAppendingPathComponent: actionString] 
				payload:[[data yajl_JSONString] dataUsingEncoding:NSUTF8StringEncoding] 
				success:@selector(httpConnection:didSendData:)];	
}

- (void)receiveWithMode: (NSString *)mode {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	
	NSString *actionString = [@"/action" stringByAppendingPathComponent:mode];
	[httpClient getURI:[uri stringByAppendingPathComponent: actionString] 
			   success:@selector(httpConnection:didReceiveData:)];	
}

- (void)disconnect {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	
	[httpClient deleteURI:[uri stringByAppendingPathComponent:@"/environment"]
				  success:@selector(httpClientDidDelete:)];
}


#pragma mark -
#pragma mark Error Handling 

- (void)httpConnection:(HttpConnection *)connection didFailWithError: (NSError *)error {
	[self didFailWithError:error];
}

- (void)didFailWithError: (NSError *)error {
	if ([delegate respondsToSelector:@selector(linccer:didFailWithError:)]) {
		[delegate linccer: self didFailWithError:error];
	}
}

#pragma mark -
#pragma mark LocationController Delegate Methods

- (void)environmentManagerDidUpdateEnvironment: (HCEnvironmentManager *)controller {
	[self updateEnvironment];
}

#pragma mark -
#pragma mark HttpClient Response Methods 

- (void)httpConnection: (HttpConnection *)aConnection didUpdateEnvironment: (NSData *)receivedData {
	if (isRegistered) {
		return;
	}
	
	isRegistered = YES;
	if ([delegate respondsToSelector:@selector(linccerDidRegister:)]) {
		[delegate linccerDidRegister:self];
	}
}

- (void)httpConnection: (HttpConnection *)connection didSendData: (NSData *)data {
	
	if ([connection.response statusCode] == 204 ) {
		NSError *error = [NSError errorWithDomain:HoccerError code:HoccerNoReceiverError userInfo:[self userInfoForNoReceiver]];
		[self didFailWithError:error];
		return;
	}
	
	if ([delegate respondsToSelector:@selector(linccer:didSendDataWithInfo:)]) {
		[delegate linccer: self didSendDataWithInfo: [data yajl_JSON]];
	}
}

- (void)httpConnection: (HttpConnection *)connection didReceiveData: (NSData *)data {

	if ([connection.response statusCode] == 204 ) {
		NSError *error = [NSError errorWithDomain:HoccerError code:HoccerNoSenderError userInfo:[self userInfoForNoSender]];
		[self didFailWithError:error];
		return;
	}

	if ([delegate respondsToSelector:@selector(linccer:didReceiveData:)]) {
		[delegate linccer: self didReceiveData: [data yajl_JSON]];
	}

}

- (void)httpClientDidDelete: (NSData *)receivedData {
	NSLog(@"deleted resource");
	if ([delegate respondsToSelector:@selector(linccerDidUnregister:)]) {
		[delegate linccerDidUnregister: self];
	}
}

#pragma mark -
#pragma mark Private Methods

- (NSDictionary *)userInfoForNoReceiver {

	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:NSLocalizedString(@"Could not establish connection", nil) forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:NSLocalizedString(@"", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
		
	return [userInfo autorelease];
}

- (NSDictionary *)userInfoForNoSender {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:NSLocalizedString(@"Could not establish connection", nil) forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:NSLocalizedString(@"", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
	
	return [userInfo autorelease];	
}

- (void)updateEnvironment {	
	if (uri == nil && [self.environmentController hasEnvironment]) {
		return;
	}
	
	[httpClient putURI:[uri stringByAppendingPathComponent:@"/environment"]
			   payload:[[environmentController.environment JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding] 
			   success:@selector(httpConnection:didUpdateEnvironment:)];
}


#pragma mark -
#pragma mark Getter

- (NSString *)uuid {
	NSString *uuid = nil;
	// uuid = [[NSUserDefaults standardUserDefaults] stringForKey:HOCCER_CLIENT_ID_KEY];
	if (!uuid) {
		uuid = [NSString stringWithUUID];
		[[NSUserDefaults standardUserDefaults] setObject:uuid forKey:HOCCER_CLIENT_ID_KEY];

	}

	return uuid;
}


- (void)dealloc {
	[httpClient cancelAllRequest];
	[httpClient release];
	[environmentController release];
    [super dealloc];
}

@end