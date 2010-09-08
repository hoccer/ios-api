//
//  HoccerRegister.m
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "HoccerRegister.h"
#import "NSString+SBJSON.h"


@implementation HoccerRegister
@synthesize delegate;

- (id) init {
	self = [super init];
	if (self != nil) {
		NSURL *url = [NSURL URLWithString:@"http://127.0.0.1:9292/clients"];
		
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
		[request setHTTPMethod:@"POST"];
		
		connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		receivedData = [[NSMutableData alloc] init];
	}
	return self;
}


#pragma mark -
#pragma mark NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	[receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	NSLog(@"error: %@", error);
}

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"response: %d", [(NSHTTPURLResponse *)response statusCode]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	NSString *string = [[[NSString alloc] initWithData:receivedData 
											  encoding:NSUTF8StringEncoding] autorelease];
	
	NSDictionary *info = [string JSONValue];
	
	if ([delegate respondsToSelector:@selector(hoccer:didRegisterWithInfo:)]) {
		[delegate hoccer:self didRegisterWithInfo: info];
	}
}


- (void)dealloc {
	[connection release];
	[receivedData release];
	
    [super dealloc];
}


@end
