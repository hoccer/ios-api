//
//  HoccerGeoStorage.m
//  HoccerAPI
//
//  Created by Robert Palmer on 14.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <YAJLIOS/YAJLIOS.h>
#import "HCGeoStorage.h"
#import "HCLocation.h"

#define HOCCER_GEOSTORAGE_URI @"http://192.168.2.139:9292"

@implementation HCGeoStorage
@synthesize delegate;

- (id) init {
	self = [super init];
	if (self != nil) {
		environmentController = [[LocationController alloc] init];
		httpClient = [[HttpClient alloc] initWithURLString:HOCCER_GEOSTORAGE_URI];
		httpClient.target = self;
	}
	return self;
}

- (CLLocation *) location {
	return environmentController.environment.location;
}

- (void)store: (NSDictionary *)data {
	NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys:
							 [environmentController.environment dict], @"environment",
							 data, @"params", nil];

	NSString *payloadJSON = [payload yajl_JSONString];
	[httpClient postURI:@"/store" 
				payload:[payloadJSON dataUsingEncoding:NSUTF8StringEncoding] 
				success:@selector(httpConnection:didSendData:)];
}

- (void)searchNearby {
	NSString *jsonEnvironment = [environmentController.environment JSONRepresentation];
	
	[httpClient postURI:@"/search" 
				payload:[jsonEnvironment dataUsingEncoding:NSUTF8StringEncoding] 
				success:@selector(httpConnection:didFindData:)];
}

#pragma mark -
#pragma mark Callback Methods

- (void)httpConnection: (HttpConnection *)connection didStoreData: (NSData *)data {
	NSLog(@"stored: %@", [data yajl_JSON]);
}

- (void)httpConnection: (HttpConnection *)connection didFindData: (NSData *)data {
	NSLog(@"found: %@", [data yajl_JSON]);
	
	if ([delegate respondsToSelector:@selector(geostorage:didFindItems:)]) {
		[delegate geostorage:self didFindItems:[data yajl_JSON]];
	}
}

- (void)httpConnection: (HttpConnection *)connection didFailWithError: (NSError *)error {
	NSLog(@"error: %@", error);
}



@end
