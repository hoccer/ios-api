//
//  Hoccer.m
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <YAJLIOS/YAJLIOS.h>
#import "HCClient.h"
#import "LocationController.h"
#import "HCLocation.h"
#import "HttpClient.h"


#define HOCCER_CLIENT_URI @"hoccerClientUri" 


@interface HCClient ()

- (void)updateEnvironment;
- (void)didFailWithError: (NSError *)error;

- (NSDictionary *)userInfoForNoReceiver;
- (NSDictionary *)userInfoForNoSender;

@end

@implementation HCClient
@synthesize delegate;
@synthesize environmentController;
@synthesize isRegistered;

- (id) init {
	self = [super init];
	if (self != nil) {
		environmentController = [[LocationController alloc] init];
		environmentController.delegate = self;

		httpClient = [[HttpClient alloc] initWithURLString:@"http://192.168.2.139:9292"];
		httpClient.target = self;

		uri = [[NSUserDefaults standardUserDefaults] stringForKey:HOCCER_CLIENT_URI];
		if (!uri) {
			[httpClient postURI:@"/clients" payload:nil success:@selector(httpConnection:didReceiveInfo:)];
		} else {
			[self updateEnvironment];
		}
	}
	
	return self;
}

- (void)send: (NSData *)data withMode: (NSString *)mode {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	
	NSString *actionString = [@"/action" stringByAppendingPathComponent:mode];
	[httpClient postURI:[uri stringByAppendingPathComponent: actionString] 
				payload:data
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

- (void)httpConneciton:(HttpConnection *)connection didFailWithError: (NSError *)error {
	[self didFailWithError:error];
}

- (void)didFailWithError: (NSError *)error {
	if ([delegate respondsToSelector:@selector(client:didFailWithError:)]) {
		[delegate client:self didFailWithError:error];
	}
}

#pragma mark -
#pragma mark LocationController Delegate Methods

- (void)locationControllerDidUpdateLocation: (LocationController *)controller {
	[self updateEnvironment];
}

#pragma mark -
#pragma mark HttpClient Response Methods 
- (void)httpConnection: (HttpConnection *)aConncetion didReceiveInfo: (NSData *)receivedData {
	
	NSString *string = [[[NSString alloc] initWithData: receivedData
											  encoding:NSUTF8StringEncoding] autorelease];
	
	NSDictionary *info = [string yajl_JSON];
	uri = [[info objectForKey:@"uri"] copy];
	
	[[NSUserDefaults standardUserDefaults] setObject:uri forKey:HOCCER_CLIENT_URI];
	
	[self updateEnvironment];
};

- (void)httpConnection: (HttpConnection *)aConnection didUpdateEnvironment: (NSData *)receivedData {
	if (isRegistered) {
		return;
	}
	
	isRegistered = YES;
	if ([delegate respondsToSelector:@selector(clientDidRegister:)]) {
		[delegate clientDidRegister:self];
	}
}

- (void)httpConnection: (HttpConnection *)connection didSendData: (NSData *)data {
	
	if ([connection.response statusCode] == 204 ) {
		NSError *error = [NSError errorWithDomain:HoccerError code:HoccerNoReceiverError userInfo:[self userInfoForNoReceiver]];
		[self didFailWithError:error];
		return;
	}
	
	if ([delegate respondsToSelector:@selector(clientDidSendData:)]) {
		[delegate clientDidSendData: self];
	}
}

- (void)httpConnection: (HttpConnection *)connection didReceiveData: (NSData *)data {

	if ([connection.response statusCode] == 204 ) {
		NSError *error = [NSError errorWithDomain:HoccerError code:HoccerNoSenderError userInfo:[self userInfoForNoSender]];
		[self didFailWithError:error];
		return;
	}

	if ([delegate respondsToSelector:@selector(client:didReceiveData:)]) {
		[delegate client: self didReceiveData: data];
	}

}

- (void)httpClientDidDelete: (NSData *)receivedData {
	NSLog(@"deleted resource");
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
	if (uri == nil) {
		return;
	}
	
	[httpClient putURI:[uri stringByAppendingPathComponent:@"/environment"]
			   payload:[[environmentController.location JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding] 
			   success:@selector(httpConnection:didUpdateEnvironment:)];
}


- (void)dealloc {
	[httpClient cancelAllRequest];
	[httpClient release];
	[environmentController release];
    [super dealloc];
}


@end
