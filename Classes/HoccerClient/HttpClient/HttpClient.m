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
//  HttpClient.m
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "HttpClient.h"
#import <YAJLIOS/YAJLIOS.h>

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
- (NSError *)hasHttpError: (NSHTTPURLResponse *)response;
@end

@implementation HttpClient

@synthesize target;
@synthesize userAgent;

- (id)initWithURLString: (NSString *)url {
	self = [super init];
	if (self != nil) {
		baseURL = [url copy];
		connections = [[NSMutableDictionary alloc] init];	
	}
	
	return self;	
}

- (NSString *)getURI: (NSString *)uri success: (SEL)success {
	return [self requestMethod:@"GET" URI: uri payload:nil success:success];
}

- (NSString *)putURI: (NSString *)uri payload: (NSData *)payload success: (SEL)success {
	return [self requestMethod:@"PUT" URI: uri payload:payload success:success];
}

- (NSString *)postURI: (NSString *)uri payload: (NSData *)payload success: (SEL)success {
	return [self requestMethod:@"POST" URI: uri payload:payload success:success];
}

- (NSString *)deleteURI: (NSString *)uri success: (SEL)success {
	return [self requestMethod:@"DELETE" URI:uri payload:nil success:success];
}

- (NSString *)requestMethod: (NSString *)method URI: (NSString *)uri payload: (NSData *)payload success: (SEL)success {
	return [self requestMethod:method absoluteURL:[NSString stringWithFormat:@"%@%@", baseURL, uri] payload:payload success:success];
}

- (NSString *)requestMethod:(NSString *)method absoluteURL:(NSString *)URLString payload:(NSData *)payload success:(SEL)success {
	return [self requestMethod:method absoluteURI:URLString payload:payload header: nil success:success];
}

- (NSString *)requestMethod:(NSString *)method URI:(NSString *)uri payload:(NSData *)payload header: (NSDictionary *)headers success:(SEL)success {
	return [self requestMethod:method absoluteURI:[NSString stringWithFormat:@"%@%@", baseURL, uri] payload:payload header: headers success:success];
}

- (NSString *)requestMethod:(NSString *)method absoluteURI:(NSString *)URLString payload:(NSData *)payload header: (NSDictionary *)headers success:(SEL)success {
	NSLog(@"%@ %@", method, URLString);

	NSURL *url = [NSURL URLWithString:URLString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	
	[request addValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
	for (NSString *key in headers) {
		[request addValue:[headers objectForKey:key] forHTTPHeaderField:key];
	}

	[request setHTTPMethod:method];
	[request setHTTPBody:payload];
	
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	HttpConnection *httpConnection = [[[HttpConnection alloc] init] autorelease];
	httpConnection.uri = URLString;
	httpConnection.request = request;
	
	ConnectionContainer *container = [ConnectionContainer containerWithConnection: connection successSelector:success];
	container.httpConnection = httpConnection;
	
	[connections setObject: container forKey:[connection description]];
	
	return URLString;	
}

#pragma mark -
#pragma mark NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	ConnectionContainer *container = [connections objectForKey:[aConnection description]];
	[container.receivedData appendData:data];
	
	CGFloat downloaded = (float)[container.receivedData length]/ [container.httpConnection.response expectedContentLength];
	if ([target respondsToSelector:@selector(httpConnection:didUpdateDownloadPercentage:)]) {
		[target performSelector:@selector(httpConnection:didUpdateDownloadPercentage:) 
					 withObject:container.httpConnection withObject: [NSNumber numberWithFloat: downloaded]];
	}
}

- (void) connection:(NSURLConnection *)aConnection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	ConnectionContainer *container = [connections objectForKey:[aConnection description]];
	
	CGFloat uploaded = (float)totalBytesWritten / totalBytesExpectedToWrite;

	if ([target respondsToSelector:@selector(httpConnection:didUpdateDownloadPercentage:)]) {
		[target performSelector:@selector(httpConnection:didUpdateDownloadPercentage:) 
					 withObject:container.httpConnection withObject: [NSNumber numberWithFloat: uploaded]];
	}
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	NSLog(@"error: %@", error);
	ConnectionContainer *container = [connections objectForKey:[aConnection description]];
	if (!container.httpConnection.canceled && [target respondsToSelector:@selector(httpConnection:didFailWithError:)]) {
		[target performSelector:@selector(httpConnection:didFailWithError:) withObject: container.httpConnection withObject:error];
	}
}

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"response: %d", [(NSHTTPURLResponse *)response statusCode]);
	
	ConnectionContainer *container = [connections objectForKey:[aConnection description]];
	container.httpConnection.response = (NSHTTPURLResponse *)response;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	ConnectionContainer *container = [connections objectForKey:[aConnection description]];
	NSError *error = [self hasHttpError: (NSHTTPURLResponse *)container.httpConnection.response];
	if (error != nil) {
		[self connection:aConnection didFailWithError:error];
	}
	
	if (!container.httpConnection.canceled && [target respondsToSelector:container.successAction]) {
		[target performSelector:container.successAction withObject:container.httpConnection withObject:container.receivedData];
	}

	[connections removeObjectForKey:[aConnection description]];
}

- (BOOL) connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void) connection:(NSURLConnection *)aConnection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}

- (void)cancelAllRequest {
	for (ConnectionContainer *container in [connections allValues]) {
		[container.connection cancel];
		container.httpConnection.canceled = YES;
	}
	
}

- (void)cancelRequest:(NSString *)uri {
	ConnectionContainer *cancelableConnection = nil;
	for (ConnectionContainer *container in [connections allValues]) {
		if ([container.httpConnection.uri isEqualToString: uri]) {
			
			cancelableConnection = container;
			break;
		}
	}
	
	[cancelableConnection.connection cancel];
	cancelableConnection.httpConnection.canceled = YES;
}

#pragma mark -
#pragma mark Getter
- (NSString *) userAgent {
	if (userAgent == nil) {
		NSMutableString *buffer = [NSMutableString string];
		[buffer appendFormat:@"%@ ", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]];
		[buffer appendFormat:@"%@ / ", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
		[buffer appendFormat:@"%@ / ", [UIDevice currentDevice].model];
		[buffer appendFormat:@"%@ %@", [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion];
		userAgent = [buffer retain];
	}
	
	return userAgent;
}

#pragma mark -
#pragma mark HTTP Error Handling 
- (NSError *)hasHttpError: (NSHTTPURLResponse *)response {
	if ([response statusCode] >= 400) {
		NSDictionary *info = [NSDictionary dictionary];
		NSError *httpError = [NSError errorWithDomain: HttpErrorDomain 
												 code: [response statusCode] 
											 userInfo: info];
		
		return httpError;
	}
	
	return nil;
}

- (void)dealloc {
	[connections release];
	[baseURL release];
	
    [super dealloc];
}

@end