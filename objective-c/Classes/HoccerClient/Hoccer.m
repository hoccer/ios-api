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
		
		[httpClient postURI:@"/clients" payload:nil success:@selector(httpClientDidReceiveInfo:)];
		
		// get id (from prefs or create new on server
	}
	return self;
}

- (void)send: (NSData *)data withMode: (NSString *)mode {
	[httpClient postURI:[uri stringByAppendingPathComponent:@"/action/distribute"] 
				payload: data
				success:@selector(httpClientDidSendData:response:)];	
}

- (void)receiveWithMode: (NSString *)mode {
	[httpClient getURI:[uri stringByAppendingPathComponent:@"/action/distribute"] 
			   success:@selector(httpClientDidReceiveData:response:)];	
}

- (void)disconnect {
	
}


#pragma mark -
#pragma mark Error Handling 

- (void)httpClient: (HttpClient *)client didFailWithError: (NSError *)error {
	NSLog(@"in Hoccer: %@", error);
}


#pragma mark -
#pragma mark LocationController Delegate Methods

- (void)locationControllerDidUpdateLocation: (LocationController *)controller {
	[self updateEnvironment];
}

#pragma mark -
#pragma mark HttpClient Response Methods 
- (void)httpClientDidReceiveInfo: (NSData *)receivedData {
	
	NSString *string = [[[NSString alloc] initWithData: receivedData
											  encoding:NSUTF8StringEncoding] autorelease];
	
	NSDictionary *info = [string JSONValue];
	uri = [[info objectForKey:@"uri"] copy];
	
	[self updateEnvironment];
};

- (void)httpClientDidUpdateEnvirinment: (NSData *)receivedData {
	if (isRegistered) {
		return;
	}
	
	isRegistered = YES;
	if ([delegate respondsToSelector:@selector(hoccerDidRegister:)]) {
		[delegate hoccerDidRegister:self];
	}
}

- (void)httpClientDidSendData: (NSData *)receivedData response: (NSHTTPURLResponse *)response  {
	if ([response statusCode] == 204 ) {
		if ([delegate respondsToSelector:@selector(hoccer:didFailWithError:)]) {
			NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
								  NSLocalizedString(@"No content found", nil), NSLocalizedDescriptionKey, nil];
			
 			NSError *error = [NSError errorWithDomain:HoccerError code:HoccerNobodyFound userInfo:info];
			[delegate hoccer:self didFailWithError:error];
		}
		
		return;
	}
	
	if ([delegate respondsToSelector:@selector(hoccerDidSendData:)]) {
		[delegate hoccerDidSendData:self];
	}
}

- (void)httpClientDidReceiveData: (NSData *)receivedData response: (NSHTTPURLResponse *)response  {
	if ([response statusCode] == 204 ) {
		if ([delegate respondsToSelector:@selector(hoccer:didFailWithError:)]) {
			NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
								  NSLocalizedString(@"No content found", nil), NSLocalizedDescriptionKey, nil];
			
 			NSError *error = [NSError errorWithDomain:HoccerError code:HoccerNobodyFound userInfo:info];
			[delegate hoccer:self didFailWithError:error];
		}
		
		return;
	}
	
	if ([delegate respondsToSelector:@selector(hoccer:didReceiveData:)]) {
		[delegate hoccer: self didReceiveData: receivedData];
	}

}

#pragma mark -
#pragma mark Private Methods
- (void)updateEnvironment {	
	
	if (uri == nil) {
		return;
	}
	
	NSLog(@"updateEnvironment: %@", [environmentController.location JSONRepresentation]);
	[httpClient putURI:[uri stringByAppendingPathComponent:@"/environment"]
			   payload:[[environmentController.location JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding] 
			   success:@selector(httpClientDidUpdateEnvirinment:)];
}


- (void)dealloc {
	NSLog(@"hoccer release");
	[httpClient cancelAllRequest];
	[httpClient release];
	[environmentController release];
    [super dealloc];
}


@end
