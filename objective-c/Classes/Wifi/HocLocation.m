//
//  HocLocation.m
//  Hoccer
//
//  Created by Robert Palmer on 27.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <YAJLIOS/YAJLIOS.h>
#import "HocLocation.h"

@interface HocLocation ()

- (NSDictionary *)locationAsDict: (CLLocation *)aLocation;
@end



@implementation HocLocation

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


- (void) dealloc {
	self.location = nil;
	self.bssids = nil;
	
	[super dealloc];
}

- (NSString *)JSONRepresentation {
	
	return [[self dict] yajl_JSONString];
}

- (NSDictionary *)dict {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	NSDictionary *locationDict = [self locationAsDict: self.location];
	if (locationDict) {
		[dict setObject:locationDict forKey: @"gps"];
	}
	
	if (self.bssids) {
		[dict setObject:self.bssids forKey:@"bssids"];
	}
	
	return dict;
}


- (NSDictionary *)locationAsDict: (CLLocation *)aLocation {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithDouble: aLocation.coordinate.latitude], @"latitude",
			[NSNumber numberWithDouble: aLocation.coordinate.longitude], @"longitude",
			// aLocation.timestamp, @"timestamp",
			[NSNumber numberWithDouble: aLocation.horizontalAccuracy], @"accuracy", nil];
}



@end
