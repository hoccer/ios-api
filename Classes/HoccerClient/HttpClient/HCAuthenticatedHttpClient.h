//
//  HCAuthenticatedHttpClient.h
//  HoccerAPI
//
//  Created by Robert Palmer on 23.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CommonCrypto/CommonHMAC.h>
#import "HttpClient.h"

@interface HCAuthenticatedHttpClient : HttpClient {
	NSString *secret;
	NSString *apiKey;
}

@property (retain) NSString *secret;
@property (retain) NSString *apiKey;

- (NSString *)signedURI: (NSString *)uri;

@end
