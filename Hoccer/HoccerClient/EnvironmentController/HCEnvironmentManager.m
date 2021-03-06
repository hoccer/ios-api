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
//  Copyright 2010 Hoccer GmbH AG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "HCEnvironmentManager.h"
#import "WifiScanner.h"
#import "HCEnvironment.h"

#undef USES_DEBUG_MESSAGES
#define USES_DEBUG_MESSAGES NO

#define hoccerMessageErrorDomain @"HoccerErrorDomain"

@interface HCEnvironmentManager ()
@property (retain) NSDate *lastLocationUpdate;
@property (retain) CLLocation *lastLocation;
@property (retain) NSArray *bssids;

- (void)updateHoccability;
+ (NSDictionary *)userInfoForImpreciseLocation: (NSDictionary *)hoccabilityInfo;
+ (NSDictionary *)userInfoForBadLocation: (NSDictionary *)hoccabilityInfo;
+ (NSDictionary *)userInfoForPerfectLocation: (NSDictionary *)hoccabilityInfo;

+ (NSString *)impoveSuggestion: (NSDictionary *)hoccabilityInfo;
@end



@implementation HCEnvironmentManager

@synthesize lastLocationUpdate;
@synthesize lastLocation;
@synthesize hoccability;
@synthesize delegate;
@synthesize bssids;

- (id) init {
	self = [super init];
	if (self != nil) {
		oldHoccability = -1;
        
        self.lastLocationUpdate = [NSDate dateWithTimeIntervalSince1970:0];
		
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
        locationManager.purpose = NSLocalizedString(@"Message_LocationManagerPurpose", nil);

        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		//[locationManager startUpdatingLocation];
		
		[WifiScanner sharedScanner].delegate = self;
		//[self updateHoccability];
		
		[[WifiScanner sharedScanner] addObserver:self forKeyPath:@"bssids" options:NSKeyValueObservingOptionNew context:nil];
	}
	
	return self;
}

- (void) dealloc {
	[[WifiScanner sharedScanner] removeObserver:self forKeyPath:@"bssids"];
	[WifiScanner sharedScanner].delegate = nil;
	
	[lastLocationUpdate release];
	[lastLocation release];
	[bssids release];

	[locationManager stopUpdatingLocation];
	[locationManager release];
	
	[super dealloc];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation 
		   fromLocation:(CLLocation *)oldLocation {
    if (self.lastLocation == nil) {
        self.lastLocation = oldLocation;
    }
    double distance = [newLocation distanceFromLocation:self.lastLocation];
    double lastUpdateAgo = [self.lastLocationUpdate timeIntervalSinceNow];
    if (USES_DEBUG_MESSAGES) {NSLog(@"EnvironmentManager:didUpdateToLocation: distance change = %f, last update %f secs ago, accuracy %f, last accuracy %f", distance, lastUpdateAgo, newLocation.horizontalAccuracy, self.lastLocation.horizontalAccuracy);}
	if (distance > 10 ||  lastUpdateAgo < -30 || newLocation.horizontalAccuracy < self.lastLocation.horizontalAccuracy) {
        [self updateHoccability];
        self.lastLocationUpdate = [NSDate date];
        self.lastLocation = newLocation;
        [self updateHoccability];
    } else {
        if (USES_DEBUG_MESSAGES) {NSLog(@"EnvironmentManager:didUpdateToLocation: distance change too small, last update too recent, accuracy not improved");}
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    if (error.code == kCLErrorDenied){
        UIAlertView *locationAlert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Title_LocationDidFail", nil) message:NSLocalizedString(@"Message_LocationDidFail", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Button_OK", nil) otherButtonTitles:nil, nil];
        [locationAlert show];
        [locationAlert release];
    }
}


- (void)wifiScannerDidUpdateBssids: (WifiScanner *)scanner {
	self.bssids = [WifiScanner sharedScanner].bssids;
	[self updateHoccability];
}

- (HCEnvironment *)environment
{
    HCEnvironment *location = [[HCEnvironment alloc]
                               initWithLocation: locationManager.location bssids:[WifiScanner sharedScanner].bssids];
    location.hoccability = hoccability;

    NSString *channel = [[NSUserDefaults standardUserDefaults] objectForKey:@"channel"];
    if ((channel != nil) && (channel.length > 0)) {
        location.channel = channel;
    }
    else {
        location.channel = nil;
    }
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
	return [self hasBSSID] || [self hasLocation];
}

- (void)updateHoccability {
	if ([delegate respondsToSelector:@selector(environmentManagerDidUpdateEnvironment:)]) {
		[delegate environmentManagerDidUpdateEnvironment: self];
	} else {
        if (USES_DEBUG_MESSAGES) {NSLog(@"Environment: no delegate for environment update");}
    }
}

- (void)deactivateLocation{
    if (USES_DEBUG_MESSAGES) {NSLog(@"Environment: stopUpdatingLocation");}
    [locationManager stopUpdatingLocation];
}
- (void)activateLocation{
    if (USES_DEBUG_MESSAGES) {NSLog(@"Environment: startUpdatingLocation");}
    [locationManager startUpdatingLocation];
}

+ (NSError *)messageForLocationInformation: (NSDictionary *)hoccabilityInfo {
	NSInteger hoc = [[hoccabilityInfo objectForKey:@"quality"] intValue];
	
	if (hoc == 0) {
		return [NSError errorWithDomain:hoccerMessageErrorDomain 
								   code:kHoccerBadLocation 
							   userInfo:[self userInfoForBadLocation: hoccabilityInfo]];
	}
	
	if (hoc == 1) {
		return [NSError errorWithDomain:hoccerMessageErrorDomain 
								   code:kHoccerImpreciseLocation 
							   userInfo:[self userInfoForImpreciseLocation: hoccabilityInfo]];
	}
	
	return [NSError errorWithDomain:hoccerMessageErrorDomain 
							   code:kHoccerPerfectLocation 
						   userInfo:[self userInfoForPerfectLocation:hoccabilityInfo]];
}

#pragma mark -
#pragma mark private userInfo Methods
+ (NSDictionary *)userInfoForImpreciseLocation: (NSDictionary *)hoccabilityInfo {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:NSLocalizedString(@"Message_LocationNotPrecise", nil) forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:[self impoveSuggestion: hoccabilityInfo] forKey:NSLocalizedRecoverySuggestionErrorKey];

	return [userInfo autorelease];
}

+ (NSDictionary *)userInfoForBadLocation: (NSDictionary *)hoccabilityInfo {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:NSLocalizedString(@"Message_LocationNotPreciseEnough", nil) forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:[self impoveSuggestion: hoccabilityInfo] forKey:NSLocalizedRecoverySuggestionErrorKey];
	
	return [userInfo autorelease];
}

+ (NSDictionary *)userInfoForPerfectLocation: (NSDictionary *)hoccabilityInfo {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:NSLocalizedString(@"Message_LocationPerfectPrecision", nil) forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:NSLocalizedString(@"RecoverySuggestion_LocationPerfectPrecision", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
	
	return [userInfo autorelease];
}

+ (NSString *)impoveSuggestion: (NSDictionary *)hoccabilityInfo {

	NSDictionary *wifi = [hoccabilityInfo objectForKey:@"wifi"];
	NSDictionary *coordinates = [hoccabilityInfo objectForKey:@"coordinates"];

    NSString *suggestion = NSLocalizedString(@"RecoverySuggestion_LocationShouldBeBetter", nil);
	
    if ([[wifi objectForKey:@"quality"] intValue] == 0) {
        suggestion = [suggestion stringByAppendingFormat:@" %@", NSLocalizedString(@"RecoverySuggestion_LocationTryTurnOnWifi", nil)];
	}
	
	if ([[coordinates objectForKey:@"quality"] intValue] == 0) {
        suggestion = [suggestion stringByAppendingFormat:@" %@", NSLocalizedString(@"RecoverySuggestion_LocationTryGoingOutside", nil)];
	}
	
    return suggestion;
}


@end
