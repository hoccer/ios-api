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
//  LocationController.m
//  Hoccer
//
//  Created by Robert Palmer on 16.03.10.
//  Copyright 2010 Art+Com AG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "HCEnvironmentManager.h"
#import "WifiScanner.h"
#import "HCEnvironment.h"

#define hoccerMessageErrorDomain @"HoccerErrorDomain"

@interface HCEnvironmentManager ()
@property (retain) NSDate *lastLocationUpdate;
@property (retain) NSArray *bssids;

- (void)updateHoccability;
- (NSDictionary *)userInfoForImpreciseLocation;
- (NSDictionary *)userInfoForBadLocation;
- (NSDictionary *)userInfoForPerfectLocation;

- (NSString *)impoveSuggestion;
@end



@implementation HCEnvironmentManager

@synthesize lastLocationUpdate;
@synthesize hoccability;
@synthesize delegate;
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
	[bssids release];

	[locationManager stopUpdatingLocation];
	[locationManager release];
	
	[super dealloc];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation 
		   fromLocation:(CLLocation *)oldLocation {
	[self updateHoccability];
	
	self.lastLocationUpdate = [NSDate date];
	[self updateHoccability];
}

- (void)wifiScannerDidUpdateBssids: (WifiScanner *)scanner {
	self.bssids = [WifiScanner sharedScanner].bssids;
	[self updateHoccability];
}

- (HCEnvironment *)environment {
	HCEnvironment *location = [[HCEnvironment alloc] 
			 initWithLocation: locationManager.location bssids:[WifiScanner sharedScanner].bssids];
	location.hoccability = hoccability;
	
	return [location autorelease];
}

- (BOOL)hasLocation {
	return (locationManager.location != nil);
}

- (BOOL)hasBadLocation {
	return (![self hasLocation] || self.environment.location.horizontalAccuracy > 200);
}

- (BOOL)hasBSSID {
	return self.bssids != nil;
}

- (BOOL)hasEnvironment {
	return [self hasBSSID] && [self hasLocation];
}

- (void)updateHoccability {
	self.hoccability = 0;
	
	if ([self hasLocation]) {
		if (locationManager.location.horizontalAccuracy < 200) {
			self.hoccability = 2;
		} else if (locationManager.location.horizontalAccuracy < 5000) {
			self.hoccability = 1;
		}
		
	}

	if ([self hasBSSID]) {
		self.hoccability += 1;
	}
	
	if (hoccability != oldHoccability) {
		if ([delegate respondsToSelector:@selector(environmentControllerDidUpdateLocation:)]) {
			[delegate environmentManagerDidUpdateEnvironment: self];
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
