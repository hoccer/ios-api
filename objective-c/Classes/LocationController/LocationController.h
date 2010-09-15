//
//  LocationController.h
//  Hoccer
//
//  Created by Robert Palmer on 16.03.10.
//  Copyright 2010 Art+Com AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WifiScannerDelegate.h"
#import "LocationControllerDelegate.h"

#define kHoccerPerfectLocation 0
#define kHoccerImpreciseLocation 1
#define kHoccerBadLocation 2

@class HCLocation;

@interface LocationController : NSObject <CLLocationManagerDelegate, WifiScannerDelegate> {
	@private 
	CLLocationManager *locationManager;

	NSInteger oldHoccability, hoccability;

	CLLocation *currentLocation;
	NSDate *lastLocationUpdate;
	NSArray *bssids;
		
	id <LocationControllerDelegate> delegate;
}

@property (assign) NSInteger hoccability;
@property (readonly) HCLocation *environment;
@property (assign) id <LocationControllerDelegate> delegate;

- (BOOL)hasLocation;
- (BOOL)hasBSSID;
- (NSError *)messageForLocationInformation;

@end
