//
//  HCFileCache.m
//  HoccerAPI
//
//  Created by Robert Palmer on 24.11.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "HCFileCache.h"
#import "NSDictionary+CSURLParams.h"
#import "NSString+URLHelper.h"

#define FILECACHE_URI @"http://filecache.sandbox.hoccer.com"
@implementation HCFileCache

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret {
	self = [super init];
	if (self != nil) {
		httpClient = [[HCAuthenticatedHttpClient alloc] initWithURLString:FILECACHE_URI];
		httpClient.apiKey = key;
		httpClient.secret = secret;
		httpClient.target = self;
	}
	
	return self;
}

#pragma mark -
#pragma mark Metods for Sending
- (void)cacheData: (NSData *)data forTimeInterval: (NSTimeInterval)interval {
	// NSDictionary *params = [NSDictionary dictionaryWithObject:@"30" forKey:@"expires_in"];
	// NSString *uri = [@"/bla.txt" stringByAppendingQuery:[params URLParams]];
	
	NSString *uri = @"/bla.txt";
	NSLog(@"uri: %@", uri);
	
	[httpClient putURI:uri payload:data success:@selector(httpConnection:didSendData:)];
}


#pragma mark -
#pragma mark Methods for Fetching
- (void)load: (NSString *)url {
	[httpClient getURI:url success:@selector(httpConnection:didReceiveData:)];
}

- (void)httpConnection: (HttpConnection *)connection didSendData: (NSData *)data {
	NSLog(@"did send data");
}


- (void)httpConnection: (HttpConnection*)connection didReceiveData: (NSData *)data {
	NSLog(@"did receive data");
}

- (void)cancenTransfer: (NSNumber *)transferId; {}



@end
