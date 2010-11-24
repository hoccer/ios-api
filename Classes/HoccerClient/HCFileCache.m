//
//  HCFileCache.m
//  HoccerAPI
//
//  Created by Robert Palmer on 24.11.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "HCFileCache.h"

#define FILECACHE_URI @"filecache.beta.hoccer.com"
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
- (void)send: (NSString *)filepath; {
	
}


#pragma mark -
#pragma mark Methods for Fetching
- (void)load: (NSString *)url {
	[httpClient getURI:url success:@selector(httpConnection:didReceiveData:)];
}

- (void)httpConnection: (HttpConnection*)connection didReceiveData: (NSData *)data {
	
}



- (void)cancenTransfer: (NSNumber *)transferId; {}



@end
