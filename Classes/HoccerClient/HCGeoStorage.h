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
#import "HCAuthenticatedHttpClient.h"
#import "HCEnvironmentManager.h"
#import "HCGeoStorageDelegate.h"

#define HCGeoStorageDefaultStorageTimeInterval -1


@interface HCGeoStorage : NSObject {
	HCEnvironmentManager *environmentController;
	HCAuthenticatedHttpClient *httpClient;
	
	id <HCGeoStorageDelegate> delegate;
}

@property (assign) id <HCGeoStorageDelegate> delegate;
@property (readonly) CLLocation *location;

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret;

- (void)storeProperties: (NSDictionary *)dictionary;
- (void)storeProperties: (NSDictionary *)dictionary forTimeInterval: (NSTimeInterval)seconds;
- (void)storeProperties: (NSDictionary *)dictionary atLocation: (CLLocationCoordinate2D)location forTimeInterval: (NSTimeInterval)seconds; 

- (void)searchNearby;
- (void)searchInRegion: (MKCoordinateRegion)region;
- (void)searchAtLocation: (CLLocationCoordinate2D)location radius: (CLLocationDistance)radius;

- (void)searchNearbyWithConditions: (NSDictionary *)conditions;
- (void)searchInRegion: (MKCoordinateRegion)region withConditions: (NSDictionary *)conditions;
- (void)searchAtLocation: (CLLocationCoordinate2D)location radius: (CLLocationDistance)radius withConditions: (NSDictionary *)conditions;

- (void)deleteRecordWithId: (NSString *)recordId;

@end
