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
//  MockedLocationManager.m
//  HoccerAPI
//
//  Created by Robert Palmer on 10.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "MockedLocationController.h"
#import "HCEnvironment.h"

static CLLocationDegrees lastLatitude = 5, lastLongitue = 5; 

@implementation MockedLocationController

- (id) init {
	self = [super init];
	if (self != nil) {	}
	return self;
}

- (HCEnvironment *)environment {
	NSArray *array = [NSArray array];
	
	CLLocationCoordinate2D coordinate;
	coordinate.latitude = lastLatitude;
	coordinate.longitude = lastLongitue;
	
	CLLocation *currentLocation = [[CLLocation alloc] initWithCoordinate:coordinate altitude:10 
													  horizontalAccuracy:100 verticalAccuracy:20 timestamp:[NSDate date]];
	
	HCEnvironment *location = [[HCEnvironment alloc] initWithLocation:currentLocation bssids:array];
	[currentLocation release];
	return [location autorelease];
}

- (void)next {
	lastLatitude = (int)(lastLatitude + 1) % 180; 
	lastLongitue = (int)(lastLongitue + 1) % 180;
}


@end
