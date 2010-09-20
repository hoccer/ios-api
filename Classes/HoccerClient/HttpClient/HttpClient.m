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
	NSMutableData *receivedData;
	NSURLConnection *connection;
	
	HttpConnection *httpConnection;
}

@property (assign) SEL successAction;
@property (readonly) NSMutableData *receivedData;
@property (retain) NSURLConnection *connection;
@property (retain) HttpConnection *httpConnection;

+ (ConnectionContainer *)containerWithConnection: (NSURLConnection *)aConnection successSelector: (SEL)selector;

@end

@implementation ConnectionContainer

@synthesize successAction;
@synthesize receivedData;
@synthesize connection;
@synthesize httpConnection;
 
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
	[receivedData release];  
	[httpConnection release];
	
	[super dealloc];
}

@end


@interface HttpClient ()

- (void)requestMethod: (NSString *)method URI: (NSString *)uri payload: (NSData *)payload success: (SEL)success;
- (BOOL)hasHttpError: (NSHTTPURLResponse *)response;

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
	[self requestMethod:@"POST" URI: uri payload:payload success:success];
}

- (void)deleteURI: (NSString *)uri success: (SEL)success {
	[self requestMethod:@"DELETE" URI:uri payload:nil success:success];
}

- (void)requestMethod: (NSString *)method URI: (NSString *)uri payload: (NSData *)payload success: (SEL)success {
	NSLog(@"%@ %@ %@", method, baseURL, uri);
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseURL, uri]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	
	[request setHTTPMethod:method];
	[request setHTTPBody:payload];

	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	HttpConnection *httpConnection = [[HttpConnection alloc] init];
	httpConnection.uri = uri;
	httpConnection.request = request;
	
	ConnectionContainer *container = [ConnectionContainer containerWithConnection: connection successSelector:success];
	container.httpConnection = httpConnection;
	
	[connections setObject: container forKey:[connection description]];
}


#pragma mark -
#pragma mark NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	ConnectionContainer *container = [connections objectForKey:[aConnection description]];
	[container.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	ConnectionContainer *container = [connections objectForKey:[aConnection description]];
	if (!canceled && [target respondsToSelector:@selector(httpConnection:didFailWithError:)]) {
		[target performSelector:@selector(httpConnection:didFailWithError:) withObject: container.httpConnection withObject:error];
	}
}

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response {
	ConnectionContainer *container = [connections objectForKey:[aConnection description]];
	container.httpConnection.response = (NSHTTPURLResponse *)response;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	ConnectionContainer *container = [connections objectForKey:[aConnection description]];
	if ([self hasHttpError: (NSHTTPURLResponse *)container.httpConnection.response]) {
		return;
	}
	
	NSLog(@"body: %@", [[[NSString alloc] initWithData:container.receivedData encoding:NSUTF8StringEncoding] autorelease]);
	
	if (!canceled && [target respondsToSelector:container.successAction]) {
		[target performSelector:container.successAction withObject:container.httpConnection withObject:container.receivedData];
	}

	[connections removeObjectForKey:[aConnection description]];
}

- (void)cancelAllRequest {
	for (ConnectionContainer *container in [connections allValues]) {
		[container.connection cancel];
	}
	
	canceled = YES;
}

#pragma mark -
#pragma mark HTTP Error Handling 
- (BOOL)hasHttpError: (NSHTTPURLResponse *)response {
	if ([response statusCode] >= 400) {
		NSDictionary *info = [NSDictionary dictionary];
		NSError *httpError = [NSError errorWithDomain: HttpErrorDomain 
												 code: [response statusCode] 
											 userInfo: info];

		if ([target respondsToSelector:@selector(httpConnection:didFailWithError:)]) {
			[target performSelector:@selector(httpConnection:didFailWithError:) withObject: self withObject:httpError];
		}
		
		return YES;
	}
	
	return NO;
}

- (void)dealloc {
	[connections release];
	[baseURL release];
	
    [super dealloc];
}

@end