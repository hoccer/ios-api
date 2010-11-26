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

@synthesize delegate;

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
	NSDictionary *params = [NSDictionary dictionaryWithObject:@"30" forKey:@"expires_in"];
	NSString *uri = [@"/bla.txt" stringByAppendingQuery:[params URLParams]];
	
	NSLog(@"uri: %@", uri);
	
	[httpClient putURI:uri payload:data success:@selector(httpConnection:didSendData:)];
}


#pragma mark -
#pragma mark Methods for Fetching
- (void)load: (NSString *)url {
	[httpClient requestMethod:@"GET" absoluteURL:url payload:nil success:@selector(httpConnection:didReceiveData:)];
}

- (void)httpConnection: (HttpConnection *)connection didSendData: (NSData *)data {
	if ([delegate respondsToSelector:@selector(fileCache:didUploadFileToPath:)]) {
		NSString *body = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		[delegate fileCache:self didUploadFileToPath:body];
	}
}

- (void)httpConnection: (HttpConnection*)connection didReceiveData: (NSData *)data {
	NSLog(@"did receive data: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
}


- (void) cancenTransfer:(NSNumber *)transferId {}

@end
