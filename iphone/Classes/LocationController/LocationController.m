//
//  LocationController.m
//  Hoccer
//
//  Created by Robert Palmer on 16.03.10.
//  Copyright 2010 Art+Com AG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "LocationController.h"
#import "WifiScanner.h"
#import "HocLocation.h"

#define hoccerMessageErrorDomain @"HoccerErrorDomain"

@interface LocationController ()
@property (retain) CLLocation *currentLocation;
- (void)updateHoccability;
- (NSDictionary *)userInfoForImpreciseLocation;
- (NSDictionary *)userInfoForBadLocation;
- (NSDictionary *)userInfoForPerfectLocation;

- (NSString *)impoveSuggestion;
@end



@implementation LocationController

@synthesize lastLocationUpdate;
@synthesize hoccability;
@synthesize delegate;
@synthesize currentLocation;
@synthesize bssids;

- (id) init {
	self = [super init];
	if (self != nil) {
		oldHoccability = -1;
		
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
		[locationManager startUpdatingLocation];
		
		[WifiScanner sharedScanner].delegate = self;
		[self updateHoccability];
		
		[[WifiScanner sharedScanner] addObserver:self forKeyPath:@"bssids" options:NSKeyValueObservingOptionNew context:nil];
	}
	
	return self;
}

- (void) dealloc {
	[[WifiScanner sharedScanner] removeObserver:self forKeyPath:@"bssids"];
	[WifiScanner sharedScanner].delegate = nil;
	
	[lastLocationUpdate release];
	[locationManager stopUpdatingLocation];
	[locationManager release];
	[bssids release];
	
	[super dealloc];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation 
		   fromLocation:(CLLocation *)oldLocation {
	self.currentLocation = newLocation;
	[self updateHoccability];
	
	self.lastLocationUpdate = [NSDate date];
	[self updateHoccability];
}

- (void)wifiScannerDidUpdateBssids: (WifiScanner *)scanner {
	self.bssids = [WifiScanner sharedScanner].bssids;
	[self updateHoccability];
}

- (HocLocation *)location {
	HocLocation *location = [[HocLocation alloc] 
			 initWithLocation: currentLocation bssids:[WifiScanner sharedScanner].bssids];
	location.hoccability = hoccability;
	
	return [location autorelease];
}

- (BOOL)hasLocation {
	return (currentLocation.horizontalAccuracy != 0.0);
}

- (BOOL)hasBadLocation {
	return (![self hasLocation] || self.location.location.horizontalAccuracy > 200);
}

- (BOOL)hasBSSID {
	return self.bssids != nil;
}

- (void)updateHoccability {
	self.hoccability = 0;
	
	if ([self hasLocation]) {
		if (currentLocation.horizontalAccuracy < 200) {
			self.hoccability = 2;
		} else if (currentLocation.horizontalAccuracy < 5000) {
			self.hoccability = 1;
		}
		
	}

	if ([self hasBSSID]) {
		self.hoccability += 1;
	}
	
	if (hoccability != oldHoccability) {
		if ([delegate respondsToSelector:@selector(locationControllerDidUpdateLocation:)]) {
			[delegate locationControllerDidUpdateLocation: self];
			oldHoccability = hoccability;
		} 
	}

}

- (NSError *)messageForLocationInformation {
	if (self.hoccability == 0) {
		return [NSError errorWithDomain:hoccerMessageErrorDomain code:kHoccerBadLocation userInfo:[self userInfoForBadLocation]];
	}
	
	if (self.hoccability == 1) {
		return [NSError errorWithDomain:hoccerMessageErrorDomain code:kHoccerImpreciseLocation userInfo:[self userInfoForImpreciseLocation]];
	}
	
	return [NSError errorWithDomain:hoccerMessageErrorDomain code:kHoccerPerfectLocation userInfo:[self userInfoForPerfectLocation]];
}

#pragma mark -
#pragma mark private userInfo Methods
- (NSDictionary *)userInfoForImpreciseLocation {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:@"Your location accuracy is imprecise!" forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:[self impoveSuggestion] forKey:NSLocalizedRecoverySuggestionErrorKey];

	return [userInfo autorelease];
}

- (NSDictionary *)userInfoForBadLocation {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:@"Your location accuracy is to imprecise for hoccing" forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:[self impoveSuggestion] forKey:NSLocalizedRecoverySuggestionErrorKey];
	
	return [userInfo autorelease];
}

- (NSDictionary *)userInfoForPerfectLocation {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:@"Your hoc location is perfect" forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:@"You suffice all requirements for reliable hoccing." forKey:NSLocalizedRecoverySuggestionErrorKey];
	
	return [userInfo autorelease];
}

- (NSString *)impoveSuggestion {
	NSMutableArray *suggestions = [[NSMutableArray alloc] initWithCapacity:2];
	NSMutableString *suggestion = [[NSMutableString alloc] init];
	
	if (![self hasBSSID]) {
		[suggestions addObject:@"turning on the phones wifi"];
	}
	
	if ([self hasBadLocation]) {
		[suggestions addObject:@"going outside"];
	}
	
	[suggestion appendString:@"Hoccer needs to locate you precisely to find your exchange partner. You can improve your location by "];
	[suggestion appendString:[suggestions componentsJoinedByString:@" or "]];

	[suggestions release];
	return [suggestion autorelease];
}


@end
