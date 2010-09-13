//
//  Hoccer.m
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "Hoccer.h"
#import "LocationController.h"
#import "HocLocation.h"
#import "HttpClient.h"
#import "NSString+SBJSON.h"


@interface Hoccer ()

- (void)updateEnvironment;
- (void)didFailWithError: (NSError *)error;

@end

@implementation Hoccer
@synthesize delegate;
@synthesize environmentController;
@synthesize isRegistered;

- (id) init {
	self = [super init];
	if (self != nil) {
		environmentController = [[LocationController alloc] init];
		environmentController.delegate = self;

		httpClient = [[HttpClient alloc] initWithURLString:@"http://192.168.2.111:9292"];
		httpClient.target = self;
		
		[httpClient postURI:@"/clients" payload:nil success:@selector(httpConnection:didReceiveInfo:)];
		
		// TODO: get id from prefs or create new on server
	}
	return self;
}

- (void)send: (NSData *)data withMode: (NSString *)mode {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	
	[httpClient postURI:[uri stringByAppendingPathComponent:@"/action/distribute"] 
				payload:data
				success:@selector(httpConnection:didReceiveData:)];	
}

- (void)receiveWithMode: (NSString *)mode {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	
	[httpClient getURI:[uri stringByAppendingPathComponent:@"/action/distribute"] 
			   success:@selector(httpConnection:didSendData:)];	
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
	if ([delegate respondsToSelector:@selector(hoccer:didFailWithError:)]) {
		[delegate hoccer:self didFailWithError:error];
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
	
	NSDictionary *info = [string JSONValue];
	uri = [[info objectForKey:@"uri"] copy];
	
	[self updateEnvironment];
};

- (void)httpConnection: (HttpConnection *)aConnection didUpdateEnvironment: (NSData *)receivedData {
	if (isRegistered) {
		return;
	}
	
	isRegistered = YES;
	if ([delegate respondsToSelector:@selector(hoccerDidRegister:)]) {
		[delegate hoccerDidRegister:self];
	}
}

- (void)httpConnection: (HttpConnection *)connection didSendData: (NSData *)data {
	if ([connection.response statusCode] == 204 ) {
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
							  NSLocalizedString(@"No content found", nil), NSLocalizedDescriptionKey, nil];
		
		NSError *error = [NSError errorWithDomain:HoccerError code:NobodyFound userInfo:info];
		[self didFailWithError:error];
		
		return;
	}
	
	if ([delegate respondsToSelector:@selector(hoccerDidSendData:)]) {
		[delegate hoccerDidSendData: self];
	}
}

- (void)httpConnection: (HttpConnection *)connection didReceiveData: (NSData *)data {

	if ([connection.response statusCode] == 204 ) {
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
							  NSLocalizedString(@"No content found", nil), NSLocalizedDescriptionKey, nil];
		
		NSError *error = [NSError errorWithDomain:HoccerError code:NobodyFound userInfo:info];
		[self didFailWithError:error];
		
		return;
	}

	if ([delegate respondsToSelector:@selector(hoccer:didReceiveData:)]) {
		[delegate hoccer: self didReceiveData: data];
	}

}

- (void)httpClientDidDelete: (NSData *)receivedData {
	NSLog(@"deleted resource");
}

#pragma mark -
#pragma mark Private Methods

//- (NSError *)createAppropriateError {
//	if ([gesture isEqual:@"Throw"]) {
//		return [NSError errorWithDomain:hoccerMessageErrorDomain code:kHoccerMessageNoCatcher userInfo:[self userInfoForNoCatcher]];
//	}
//	
//	if ([gesture isEqual:@"Catch"]) {
//		return [NSError errorWithDomain:hoccerMessageErrorDomain code:kHoccerMessageNoThrower userInfo:[self userInfoForNoThrower]];
//	}
//	
//	return [NSError errorWithDomain:hoccerMessageErrorDomain code:kHoccerMessageNoSecondSweeper userInfo:[self userInfoForNoSecondSweeper]];
//}
//
//- (NSError *)createAppropriateCollisionError {
//	return [NSError errorWithDomain:hoccerMessageErrorDomain code:kHoccerMessageCollision userInfo:[self userInfoForInterception]];
//}


- (NSDictionary *)userInfoForNoReceiver {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:NSLocalizedString(@"No receiver found", nil) forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:NSLocalizedString(@".", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
	
	return [userInfo autorelease];
}

- (NSDictionary *)userInfoForNoSender {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:NSLocalizedString(@"No sender found!", nil) forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:NSLocalizedString(@".", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
	
	return [userInfo autorelease];	
}

- (NSDictionary *)userInfoForInterception {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:NSLocalizedString(@"Transfere has been intercepted", nil) forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:NSLocalizedString(@".", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
	
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
