//
//  HocLocation.m
//  Hoccer
//
//  Created by Robert Palmer on 27.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HocLocation.h"


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



@end
