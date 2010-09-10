//
//  MockedLocationManager.m
//  HoccerAPI
//
//  Created by Robert Palmer on 10.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "MockedLocationController.h"
#import "HocLocation.h"

@implementation MockedLocationController


- (id) init {
	self = [super init];
	if (self != nil) {
		lastLatitude = 5;
		lastLongitue = 5;
	}
	return self;
}

- (HocLocation *)location {
	NSArray *array = [NSArray array];
	
	CLLocationCoordinate2D coordinate;
	coordinate.latitude = lastLatitude;
	coordinate.longitude = lastLongitue;
	
	CLLocation *currentLocation = [[CLLocation alloc] initWithCoordinate:coordinate altitude:10 
													  horizontalAccuracy:100 verticalAccuracy:20 timestamp:[NSDate date]];
	
	HocLocation *location = [[HocLocation alloc] initWithLocation:currentLocation bssids:array];
	return location;
}

- (void)next {
	lastLatitude += 1; lastLongitue += 1;
}


@end
