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
@synthesize isRegistered;

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
	[httpClient postURI:[uri stringByAppendingPathComponent:@"/action/distribute"] 
				payload:[@"{hallo: \"Welt\"}" dataUsingEncoding:NSUTF8StringEncoding]
				success:@selector(httpClientDidSendData:)];	
}

- (void)receiveWithMode: (NSString *)mode {
	[httpClient getURI:[uri stringByAppendingPathComponent:@"/action/distribute"] 
				success:@selector(httpClientDidReceiveData:)];	
}

- (void)peek {
}

- (void)disconnect {
	
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

- (void)httpClientDidSendData: (NSData *)receivedData {
	NSLog(@"send");
}

- (void)httpClientDidReceiveData: (NSData *)receivedData {
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
	
	[httpClient putURI:[uri stringByAppendingPathComponent:@"/environment"]
			   payload:[[environmentController.location JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding] 
			   success:@selector(httpClientDidUpdateEnvirinment:)];
}


- (void)dealloc {
	[httpClient release];
    [super dealloc];
}


@end
