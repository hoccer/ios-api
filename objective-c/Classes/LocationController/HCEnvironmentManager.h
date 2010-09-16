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
#import "HCEnvironmentManagerDelegate.h"

#define kHoccerPerfectLocation 0
#define kHoccerImpreciseLocation 1
#define kHoccerBadLocation 2

@class HCEnvironment;

@interface HCEnvironmentManager : NSObject <CLLocationManagerDelegate, WifiScannerDelegate> {
	@private 
	CLLocationManager *locationManager;

	NSInteger oldHoccability, hoccability;

	CLLocation *currentLocation;
	NSDate *lastLocationUpdate;
	NSArray *bssids;
		
	id <HCEnvironmentManagerDelegate> delegate;
}

@property (assign) NSInteger hoccability;
@property (readonly) HCEnvironment *environment;
@property (assign) id <HCEnvironmentManagerDelegate> delegate;

- (BOOL)hasLocation;
- (BOOL)hasBSSID;
- (NSError *)messageForLocationInformation;

@end
