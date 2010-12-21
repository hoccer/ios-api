//
//  HocLocation.m
//  Hoccer
//
//  Created by Robert Palmer on 27.01.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <YAJLIOS/YAJLIOS.h>
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
	return [[self dict] yajl_JSONString];
}

- (NSDictionary *)dict {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	
	if (self.location) {
		NSDictionary *locationDict = [self locationAsDict: self.location];
		[dict setObject:locationDict forKey: @"gps"];
	}
	
	if (self.bssids) {
		[dict setObject:self.bssids forKey:@"bssids"];
	}
	
	NSLog(@"dict: %@", dict);
	
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
