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
//  HttpConnection.m
//  HoccerAPI
//
//  Created by Robert Palmer on 14.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "HttpConnection.h"

@interface NSString (HCString)
- (BOOL)hc_contains: (NSString *)otherString;
@end

@implementation NSString (HCString)

- (BOOL)hc_contains: (NSString *)substring {
	return ([self rangeOfString:substring].location != NSNotFound);
}

@end


@implementation HttpConnection

@synthesize uri;
@synthesize request, response;
@synthesize startTimestamp;
@synthesize endTimestamp;
@synthesize canceled;
@synthesize bgTask;

- (void) dealloc {
	[request release];
	[response release];
	[uri release];
	
	[super dealloc];
}

- (NSTimeInterval) roundTripTime {
	if (!self.startTimestamp || !self.endTimestamp) {
		return -1;
	}
	
	return [self.endTimestamp timeIntervalSinceDate:self.startTimestamp];
}

- (BOOL) isLongpool {
	return [self.uri hc_contains:@"waiting=true"];
}

@end
