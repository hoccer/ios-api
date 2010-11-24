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

- (void)send: (NSString *)filepath; {}
- (void)load: (NSString *)url; {}
- (void)cancenTransfer: (NSNumber *)transferId; {}



@end
