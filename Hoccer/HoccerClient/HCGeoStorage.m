//  Copyright (C) 2010, Hoccer GmbH Berlin, Germany <www.hoccer.com>
//  
//  These coded instructions, statements, and computer programs contain
//  proprietary information of Linccer GmbH Berlin, and are copy protected
//  by law. They may be used, modified and redistributed under the terms
//  of GNU General Public License referenced below. 
//  
//  Alternative licensing without the obligations of the GPL is
//  available upon request.
//  
//  GPL v3 Licensing:
    
//  This file is part of the "Linccer iOS-API".
    
//  Linccer iOS-API is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
    
//  Linccer iOS-API is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
    
//  You should have received a copy of the GNU General Public License
//  along with Linccer iOS-API. If not, see <http://www.gnu.org/licenses/>.
//
//  HoccerGeoStorage.m
//  HoccerAPI
//
//  Created by Robert Palmer on 14.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <YAJLiOS/YAJL.h>
#import <MapKit/MapKit.h>
#import "HCGeoStorage.h"
#import "HCEnvironment.h"

#define HOCCER_GEOSTORAGE_URI @"https://geostore.sandbox.hoccer.com/v3"

@interface HCGeoStorage ()

- (NSArray *)arrayFromCLLocationCoordinate: (CLLocationCoordinate2D)coordinate;
- (void)storeDictionary:(NSDictionary *)dictionary withEnvironment:(HCEnvironment *)environment 
		forTimeInterval: (NSTimeInterval)seconds ;
- (void)searchForEnvironment: (HCEnvironment *)environment withProperties: (NSDictionary *)properties;

@end

@implementation HCGeoStorage
@synthesize delegate;

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret {
	self = [super init];
	if (self != nil) {
		environmentController = [[HCEnvironmentManager alloc] init];
		httpClient = [[HCAuthenticatedHttpClient alloc] initWithURLString:HOCCER_GEOSTORAGE_URI];
		httpClient.target = self;
		httpClient.secret = secret;
		httpClient.apiKey = key;
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
    [environment release];
}

- (void)storeDictionary:(NSDictionary *)dictionary 
		withEnvironment:(HCEnvironment *)environment 
		forTimeInterval: (NSTimeInterval)seconds 
{
	NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							 [environment dict], @"environment",
							 dictionary, @"data", nil];
	
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
	[self searchForEnvironment:environmentController.environment withProperties: nil];
}

- (void)searchAtLocation: (CLLocationCoordinate2D)location radius: (CLLocationDistance)radius {
	[self searchAtLocation:location radius:radius withConditions:nil];
}

- (void)searchNearbyWithConditions: (NSDictionary *)properties; {
	[self searchForEnvironment:environmentController.environment withProperties: properties];
}

- (void)searchAtLocation: (CLLocationCoordinate2D)location radius: (CLLocationDistance)radius 
		  withConditions: (NSDictionary *)properties 
{
	HCEnvironment *environment = [[[HCEnvironment alloc] initWithCoordinate:location accuracy: radius] autorelease];
	[self searchForEnvironment:environment withProperties: properties];
}


- (void)searchForEnvironment: (HCEnvironment *)environment withProperties:(NSDictionary *)properties {
	NSMutableDictionary *query = [[[environment dict] mutableCopy] autorelease];
	
	if (properties != nil) {
		[query setObject:properties forKey:@"conditions"];
	}
	
	[httpClient postURI:@"/query" 
				payload:[[query yajl_JSONString] dataUsingEncoding:NSUTF8StringEncoding] 
				success:@selector(httpConnection:didFindData:)];
}

- (void)searchInRegion: (MKCoordinateRegion)region {
	[self searchInRegion:region withConditions: nil];
}

- (void)searchInRegion: (MKCoordinateRegion)region withConditions: (NSDictionary *)properties {
	CLLocationCoordinate2D lowerLeft, upperRight;
	lowerLeft.latitude = region.center.latitude - region.span.latitudeDelta / 2;
	lowerLeft.longitude = region.center.longitude - region.span.longitudeDelta / 2;
	
	upperRight.latitude = region.center.latitude + region.span.latitudeDelta / 2;
	upperRight.longitude = region.center.longitude + region.span.longitudeDelta / 2;
	
	NSArray *boundingBox = [NSArray arrayWithObjects:
							[self arrayFromCLLocationCoordinate:lowerLeft],
							[self arrayFromCLLocationCoordinate:upperRight], nil];
	
	NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObject:boundingBox forKey:@"bbox"];
	
	if (properties != nil) {
		[query setObject:properties forKey:@"conditions"];
	}
	
	[httpClient postURI:@"/query" 
				payload:[[query yajl_JSONString] dataUsingEncoding:NSUTF8StringEncoding] 
				success:@selector(httpConnection:didFindData:)];
	
}

#pragma mark -
#pragma mark Delete Methods

- (void)deleteRecordWithId: (NSString *)propertiesId {
	[httpClient deleteURI:[@"/store" stringByAppendingPathComponent:propertiesId]  
				   success:@selector(httpConnectionDidDelete:)];
}

#pragma mark -
#pragma mark Callback Methods

- (void)httpConnection: (HttpConnection *)connection didStoreData: (NSData *)data {
    NSLog(@"did Store Data");
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
