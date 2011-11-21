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

- (NSString *)requestMethod:(NSString *)method absoluteURI:(NSString *)URLString payload:(NSData *)payload header: (NSDictionary *)headers success:(SEL)success {
	return [super requestMethod:method absoluteURI:[self signedURI:URLString] payload:payload header:headers success:success];
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
