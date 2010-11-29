//
//  HCAuthenticatedHttpClient.m
//  HoccerAPI
//
//  Created by Robert Palmer on 23.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "HCAuthenticatedHttpClient.h"
#import "NSDictionary+CSURLParams.h"
#import "NSString+URLHelper.h"
#import "NSData_Base64Extensions.h"

@implementation HCAuthenticatedHttpClient

@synthesize secret, apiKey;

- (void) requestMethod:(NSString *)method URI:(NSString *)uri payload:(NSData *)payload success:(SEL)success {
	[super requestMethod:method URI:[self signedURI:uri] payload:payload success:success];
}

- (NSString *)signedURI: (NSString *)uri {
	long timestamp = [[NSDate date] timeIntervalSince1970];
	NSString *path = [uri stringByRemovingQuery];
	NSString *paramsString = [uri URLQuery];
	
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithURLParams:paramsString];
	[params setObject:apiKey forKey:@"api_key"];
	[params setObject:[[NSNumber numberWithDouble:timestamp] stringValue] forKey:@"timestamp"];
	
	NSString *newUri = [path stringByAppendingQuery: [params URLParams]];
	
	const char *cKey  = [secret cStringUsingEncoding:NSASCIIStringEncoding];
	const char *cData = [newUri cStringUsingEncoding:NSASCIIStringEncoding];
	
	unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
	
	CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
	
	NSData *HMAC = [[[NSData alloc] initWithBytes:cHMAC
										  length:sizeof(cHMAC)] autorelease];
		
	return [NSString stringWithFormat:@"%@&signature=%@", newUri, [[HMAC asBase64EncodedString] urlEncodeValue]];
}

@end
