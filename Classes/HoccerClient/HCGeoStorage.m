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
#import "HCEnvironment.h"

#define HOCCER_GEOSTORAGE_URI @"http://beta.hoccer.com/v3"

@interface HCGeoStorage ()

- (NSArray *)arrayFromCLLocationCoordinate: (CLLocationCoordinate2D)coordinate;
- (void)storeDictionary:(NSDictionary *)dictionary withEnvironment:(HCEnvironment *)environment 
		forTimeInterval: (NSTimeInterval)seconds ;

@end

@implementation HCGeoStorage
@synthesize delegate;

- (id) init {
	self = [super init];
	if (self != nil) {
		environmentController = [[HCEnvironmentManager alloc] init];
		httpClient = [[HttpClient alloc] initWithURLString:HOCCER_GEOSTORAGE_URI];
		httpClient.target = self;
	}
	return self;
}

- (void) dealloc {
	[httpClient release];
	[environmentController release];
	
	[super dealloc];
}

- (CLLocation *)location {
	return environmentController.environment.location;
}

- (void)store: (NSDictionary *)dictionary {
	[self storeDictionary:dictionary withEnvironment:environmentController.environment 
		  forTimeInterval: HCGeoStorageDefaultStorageTimeInterval];
}

- (void)store: (NSDictionary *)dictionary forTimeInterval: (NSTimeInterval)seconds {
	[self storeDictionary:dictionary withEnvironment:environmentController.environment 
		  forTimeInterval: seconds];
}

- (void)storeDictionary: (NSDictionary *)dictionary atLocation: (CLLocationCoordinate2D)location
		forTimeInterval: (NSTimeInterval)seconds 
{
	HCEnvironment *environment = [[HCEnvironment alloc] initWithCoordinate: location];
	[self storeDictionary:dictionary withEnvironment: environment forTimeInterval: seconds];
}

- (void)storeDictionary:(NSDictionary *)dictionary 
		withEnvironment:(HCEnvironment *)environment 
		forTimeInterval: (NSTimeInterval)seconds 
{
	NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							 [environment dict], @"environment",
							 dictionary, @"params", nil];
	
	if (seconds > 0.0) {
		[payload setObject:[NSNumber numberWithDouble:seconds] forKey:@"time_interval"];
	}
	
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

- (void)searchInRegion: (MKCoordinateRegion)region {
	CLLocationCoordinate2D lowerLeft, upperRight;
	lowerLeft.latitude = region.center.latitude - region.span.latitudeDelta / 2;
	lowerLeft.longitude = region.center.longitude - region.span.longitudeDelta / 2;
	
	upperRight.latitude = region.center.latitude + region.span.latitudeDelta / 2;
	upperRight.longitude = region.center.longitude + region.span.longitudeDelta / 2;

	NSArray *boundingBox = [NSArray arrayWithObjects:
							[self arrayFromCLLocationCoordinate:lowerLeft],
							[self arrayFromCLLocationCoordinate:upperRight], nil];
	
	NSString *jsonPayload = [[NSDictionary dictionaryWithObject:boundingBox forKey:@"box"] yajl_JSONString];
	
	[httpClient postURI:@"/query" 
				payload:[jsonPayload dataUsingEncoding:NSUTF8StringEncoding] 
				success:@selector(httpConnection:didFindData:)];
}

- (void)searchAtLocation: (CLLocationCoordinate2D)location radius: (CLLocationDistance)radius {
	
}


#pragma mark -
#pragma mark Callback Methods

- (void)httpConnection: (HttpConnection *)connection didStoreData: (NSData *)data {
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
	if ([delegate respondsToSelector:@selector(geostorage:didFailWithError:)]) {
		[delegate geostorage:self didFailWithError:error];
	}
}

								  
#pragma mark -
#pragma mark Coordinate Formating Helper
- (NSArray *)arrayFromCLLocationCoordinate: (CLLocationCoordinate2D)coordinate {
	return [NSArray arrayWithObjects:
			[NSNumber numberWithDouble:coordinate.longitude],
			[NSNumber numberWithDouble:coordinate.latitude], nil];
}
							
					
@end
