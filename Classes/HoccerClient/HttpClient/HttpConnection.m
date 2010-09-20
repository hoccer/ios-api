//
//  HttpConnection.m
//  HoccerAPI
//
//  Created by Robert Palmer on 14.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "HttpConnection.h"


@implementation HttpConnection

@synthesize uri;
@synthesize request, response;

-(void) dealloc {
	[request release];
	[response release];
	[uri release];
	
	[super dealloc];
}


@end
