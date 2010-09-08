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

@implementation Hoccer
@synthesize delegate;

- (id) init {
	self = [super init];
	if (self != nil) {
		environmentController = [[LocationController alloc] init];
		environmentController.delegate = self;
		
		httpClient = [[HttpClient alloc] initWithURLString:@"http://192.168.2.139:9292"];
		httpClient.target = self;
		
		[httpClient postURI:@"/clients" payload:nil success:@selector(httpClientDidReceiveInfo:)];
		
		// get id (from prefs or create new on server
	}
	return self;
}

- (void)send: (NSData *)data withMode: (NSString *)mode {
}

- (void)receiveWithMode: (NSString *)mode {
}

- (void)peek {
}

- (void)disconnect {
	
}


#pragma mark -
#pragma mark LocationController Delegate Methods

- (void)locationControllerDidUpdateLocation: (LocationController *)controller {
	NSLog(@"environment: %@", [controller.location JSONRepresentation]);
	if (uri == nil) {
		return;
	}
	
	[httpClient putURI:[uri stringByAppendingPathComponent:@"/environment"]
			   payload:[[controller.location JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding] 
			   success:@selector(httpClientDidUpdateEnvirinment:)];
}

#pragma mark -
#pragma mark HttpClient Response Methods 
- (void)httpClientDidReceiveInfo: (NSData *)receivedData {
	
	NSString *string = [[[NSString alloc] initWithData: receivedData
											  encoding:NSUTF8StringEncoding] autorelease];
	
	NSDictionary *info = [string JSONValue];
	uri = [[info objectForKey:@"uri"] copy];
	
	NSLog(@"uri: %@", uri);
}

- (void)httpClientDidUpdateEnvirinment: (NSData *)receivedData {
	NSLog(@"updated location");
}




- (void)dealloc {
    [super dealloc];
}


@end
