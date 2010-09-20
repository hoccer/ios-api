//
//  HoccerGeoStorage.h
//  HoccerAPI
//
//  Created by Robert Palmer on 14.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "HttpClient.h"
#import "HCEnvironmentManager.h"
#import "HCGeoStorageDelegate.h"

#define HCGeoStorageDefaultStorageTimeInterval -1


@interface HCGeoStorage : NSObject {
	HCEnvironmentManager *environmentController;
	HttpClient *httpClient;
	
	id <HCGeoStorageDelegate> delegate;
}

@property (assign) id <HCGeoStorageDelegate> delegate;
@property (readonly) CLLocation *location;

- (void)store: (NSDictionary *)dictionary;
- (void)store: (NSDictionary *)dictionary forTimeInterval: (NSTimeInterval)seconds;
- (void)storeDictionary: (NSDictionary *)dictionary atLocation: (CLLocationCoordinate2D)location forTimeInterval: (NSTimeInterval)seconds; 

- (void)searchNearby;
- (void)searchInRegion: (MKCoordinateRegion)region;
- (void)searchAtLocation: (CLLocationCoordinate2D)location radius: (CLLocationDistance)radius;

// - (void)searchNearbyFor: (HCQuery *)query;
// - (void)searchFor: (HCQuery *)query inRegion: (MKCoordinateRegion)region;

@end
