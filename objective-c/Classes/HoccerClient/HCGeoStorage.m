//
//  HoccerGeoStorage.m
//  HoccerAPI
//
//  Created by Robert Palmer on 14.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <YAJLIOS/YAJLIOS.h>
#import <MapKit/MapKit.h>
#import "HCGeoStorage.h"
#import "HCLocation.h"

#define HOCCER_GEOSTORAGE_URI @"http://192.168.2.131:9292"

@interface HCGeoStorage ()

- (NSArray *)arrayFromCLLocationCoordinate: (CLLocationCoordinate2D)coordinate;

@end

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
	
	[httpClient postURI:@"/query" 
				payload:[jsonEnvironment dataUsingEncoding:NSUTF8StringEncoding] 
				success:@selector(httpConnection:didFindData:)];
}

- (void)searchInArea: (MKCoordinateRegion)region {
	CLLocationCoordinate2D lowerLeft, upperRight;
	lowerLeft.latitude = region.center.latitude - region.span.latitudeDelta;
	lowerLeft.longitude = region.center.longitude - region.span.longitudeDelta;
	
	upperRight.latitude = region.center.latitude + region.span.latitudeDelta;
	upperRight.longitude = region.center.longitude + region.span.longitudeDelta;

	NSArray *boundingBox = [NSArray arrayWithObjects:
							[self arrayFromCLLocationCoordinate:lowerLeft],
							[self arrayFromCLLocationCoordinate:upperRight], nil];
	
	NSString *jsonPayload = [[NSDictionary dictionaryWithObject:boundingBox forKey:@"box"] yajl_JSONString];
	
	[httpClient postURI:@"/query" 
				payload:[jsonPayload dataUsingEncoding:NSUTF8StringEncoding] 
				success:@selector(httpConnection:didFindData:)];
}

#pragma mark -
#pragma mark Callback Methods

- (void)httpConnection: (HttpConnection *)connection didStoreData: (NSData *)data {
	NSLog(@"stored: %@", [data yajl_JSON]);
	if ([delegate respondsToSelector:@selector(geostorageDidFinishStoring:)]) {
		[delegate geostorageDidFinishStoring: self];
	}
}

- (void)httpConnection: (HttpConnection *)connection didFindData: (NSData *)data {	
	if ([delegate respondsToSelector:@selector(geostorage:didFindItems:)]) {
		[delegate geostorage:self didFindItems:[data yajl_JSON]];
	}
}

- (void)httpConnection: (HttpConnection *)connection didFailWithError: (NSError *)error {
	NSLog(@"error: %@", error);
}

								  
#pragma mark -
#pragma mark Coordinate Formating Helper
- (NSArray *)arrayFromCLLocationCoordinate: (CLLocationCoordinate2D)coordinate {
	return [NSArray arrayWithObjects:
			[NSNumber numberWithDouble:coordinate.longitude],
			[NSNumber numberWithDouble:coordinate.latitude], nil];
}
							
					
@end
