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
//  HocLocation.m
//  Hoccer
//
//  Created by Robert Palmer on 27.01.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <YAJLiOs/YAJL.h>
#import "HCEnvironment.h"

@interface HCEnvironment ()
- (NSDictionary *)locationAsDict: (CLLocation *)aLocation;
@end

@implementation HCEnvironment

@synthesize location;
@synthesize bssids;
@synthesize hoccability;

- (id) initWithLocation: (CLLocation *)theLocation bssids: (NSArray*) theBssids {
	self = [super init];
	if (self != nil) {
		self.location = theLocation;
		self.bssids = theBssids;
	}
	return self;
}

- (id)initWithCoordinate: (CLLocationCoordinate2D)coordinate accuracy: (CLLocationAccuracy)accuracy {
	CLLocation *newlocation = [[[CLLocation alloc] initWithCoordinate:coordinate altitude:0 
												 horizontalAccuracy:accuracy verticalAccuracy:accuracy 
															timestamp:[NSDate date]] autorelease];
	
	return [self initWithLocation:newlocation bssids:nil];
}

- (void) dealloc {
	[location release];
	[bssids release];
	
	[super dealloc];
}

- (NSString *)JSONRepresentation {
    
    @try {
        return [[self dict] yajl_JSONString];
	}
	@catch (NSException * e) { NSLog(@"%@", e); }
    
    return nil;
}

- (NSDictionary *)dict {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	
	if (self.location) {
		NSDictionary *locationDict = [self locationAsDict: self.location];
		[dict setObject:locationDict forKey: @"gps"];
	}
	
	if (self.bssids) {
		NSDictionary *wifi = [NSDictionary dictionaryWithObjectsAndKeys:
							  self.bssids, @"bssids",
							  [NSNumber numberWithDouble: [[NSDate date] timeIntervalSince1970]], @"timestamp", nil];
		
		[dict setObject:wifi forKey:@"wifi"];
	}
		
	return dict;
}


- (NSDictionary *)locationAsDict: (CLLocation *)aLocation {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithDouble: aLocation.coordinate.latitude], @"latitude",
			[NSNumber numberWithDouble: aLocation.coordinate.longitude], @"longitude",
			[NSNumber numberWithDouble: [aLocation.timestamp timeIntervalSince1970]], @"timestamp",
			[NSNumber numberWithDouble: aLocation.horizontalAccuracy], @"accuracy", nil];
}



@end
