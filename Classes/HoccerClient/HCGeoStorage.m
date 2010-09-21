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

// #define HOCCER_GEOSTORAGE_URI @"http://beta.hoccer.com/v3"
#define HOCCER_GEOSTORAGE_URI @"http://192.168.2.155:9292"


@interface HCGeoStorage ()

- (NSArray *)arrayFromCLLocationCoordinate: (CLLocationCoordinate2D)coordinate;
- (void)storeDictionary:(NSDictionary *)dictionary withEnvironment:(HCEnvironment *)environment 
		forTimeInterval: (NSTimeInterval)seconds ;
- (void)searchForEnvironment: (HCEnvironment *)environment;


@end

@implementation HCGeoStorage
@synthesize delegate;

- (id) init {
	self = [super init];
	if (self != nil) {
		environmentController = [[HCEnvironmentManager alloc] init];
		NSLog(@"url: %@", HOCCER_GEOSTORAGE_URI);
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

#pragma mark -
#pragma mark Methods for Storing
- (void)storeProperties: (NSDictionary *)dictionary {
	[self storeDictionary:dictionary withEnvironment:environmentController.environment 
		  forTimeInterval: HCGeoStorageDefaultStorageTimeInterval];
}

- (void)storeProperties: (NSDictionary *)dictionary forTimeInterval: (NSTimeInterval)seconds {
	[self storeDictionary:dictionary withEnvironment:environmentController.environment 
		  forTimeInterval: seconds];
}

- (void)storeProperties: (NSDictionary *)dictionary atLocation: (CLLocationCoordinate2D)location
		forTimeInterval: (NSTimeInterval)seconds 
{
	HCEnvironment *environment = [[HCEnvironment alloc] initWithCoordinate: location accuracy:5];
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
		[payload setObject:[NSNumber numberWithDouble:seconds] forKey:@"lifetime"];
	}
	
	NSString *payloadJSON = [payload yajl_JSONString];
	[httpClient postURI:@"/store" 
				payload:[payloadJSON dataUsingEncoding:NSUTF8StringEncoding] 
				success:@selector(httpConnection:didStoreData:)];
}


#pragma mark -
#pragma mark Methods for Searching
- (void)searchNearby {
	[self searchForEnvironment:environmentController.environment];
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
	HCEnvironment *environment = [[[HCEnvironment alloc] initWithCoordinate:location accuracy: radius] autorelease];
	[self searchForEnvironment:environment];
}

- (void)searchForEnvironment: (HCEnvironment *)environment {
	NSString *jsonEnvironment = [environment JSONRepresentation];
	
	[httpClient postURI:@"/query" 
				payload:[jsonEnvironment dataUsingEncoding:NSUTF8StringEncoding] 
				success:@selector(httpConnection:didFindData:)];
}

#pragma mark -
#pragma mark Delete Methods

- (void)deletePropertiesWithId: (NSString *)propertiesId {
	[httpClient deleteURI:[@"/store" stringByAppendingPathComponent:propertiesId]  
				   success:@selector(httpConnectionDidDelete:)];
}

#pragma mark -
#pragma mark Callback Methods

- (void)httpConnection: (HttpConnection *)connection didStoreData: (NSData *)data {
	NSDictionary *response = [data yajl_JSON];
	NSString *propertyId = [[response objectForKey:@"url"] lastPathComponent];
	
	if ([delegate respondsToSelector:@selector(geostorage:didFinishStoringWithId:)]) {
		[delegate geostorage: self didFinishStoringWithId:propertyId];
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
