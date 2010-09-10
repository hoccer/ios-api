//
//  HttpClient.m
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "HttpClient.h"

@interface ConnectionContainer : NSObject 
{
	SEL successAction;
	NSURLConnection *connection;
	NSMutableData *receivedData;
	NSURLResponse *response;
}

@property (assign) SEL successAction;
@property (readonly) NSMutableData *receivedData;
@property (retain) NSURLResponse *response;
@property (retain) NSURLConnection *connection;

+ (ConnectionContainer *)containerWithConnection: (NSURLConnection *)aConnection successSelector: (SEL)selector;

@end

@implementation ConnectionContainer

@synthesize successAction;
@synthesize receivedData;
@synthesize response;
@synthesize connection;
 
+ (ConnectionContainer *)containerWithConnection: (NSURLConnection *)aConnection successSelector: (SEL)selector {
	ConnectionContainer *c = [[ConnectionContainer alloc] init];
	c.successAction = selector;
	c.connection = [aConnection retain];
	
	return [c autorelease];
}

- (id) init {
	self = [super init];
	if (self != nil) {
		receivedData = [[NSMutableData alloc] init];
	}
	return self;
}

- (void) dealloc {
	[connection release];
	[response release];
	[receivedData release];  
	[super dealloc];
}

@end


@interface HttpClient ()

- (void)requestMethod: (NSString *)method URI: (NSString *)uri payload: (NSData *)payload success: (SEL)success;

@end

@implementation HttpClient

@synthesize target;

- (id)initWithURLString: (NSString *)url {
	self = [super init];
	if (self != nil) {
		baseURL = [url copy];
		
		connections = [[NSMutableDictionary alloc] init];	
	}
	
	return self;	
}

- (void)getURI: (NSString *)uri success: (SEL)success {
	[self requestMethod:@"GET" URI: uri payload:nil success:success];
}

- (void)putURI: (NSString *)uri payload: (NSData *)payload success: (SEL)success {
	[self requestMethod:@"PUT" URI: uri payload:payload success:success];
}

- (void)postURI: (NSString *)uri payload: (NSData *)payload success: (SEL)success {
	return [self requestMethod:@"POST" URI: uri payload:payload success:success];
};

- (void)requestMethod: (NSString *)method URI: (NSString *)uri payload: (NSData *)payload success: (SEL)success {
	NSLog(@"%@ %@", method, uri);
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseURL, uri]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	
	[request setHTTPMethod:method];
	[request setHTTPBody:payload];
	
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	[connections setObject:[ConnectionContainer containerWithConnection: connection successSelector:success] forKey:[connection description]];
}


#pragma mark -
#pragma mark NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	ConnectionContainer *container = [connections objectForKey:[aConnection description]];
	[container.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	if (!canceled && [target respondsToSelector:@selector(httpClient:didFailWithError:)]) {
		[target performSelector:@selector(httpClient:didFailWithError:) withObject: self withObject:error];
	}
}

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"responseCode: %d", [(NSHTTPURLResponse*)response statusCode]);
	
	ConnectionContainer *container = [connections objectForKey:[aConnection description]];
	container.response = response;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	ConnectionContainer *container = [connections objectForKey:[aConnection description]];
	
	
	NSLog(@"received: %@", [[[NSString alloc] initWithData:container.receivedData
												  encoding:NSUTF8StringEncoding] autorelease]);
	
	if (!canceled && [target respondsToSelector:container.successAction]) {
		[target performSelector:container.successAction withObject:container.receivedData withObject:container.response];
	}

	[connections removeObjectForKey:[aConnection description]];
}

- (void)cancelAllRequest {
	for (ConnectionContainer *container in [connections allValues]) {
		[container.connection cancel];
	}
	canceled = YES;
}

- (void)dealloc {
    [super dealloc];
}


@end
