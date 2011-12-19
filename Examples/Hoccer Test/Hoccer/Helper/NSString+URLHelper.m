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
//  NSString+URLHelper.m
//  HoccerAPI
//
//  Created by Robert Palmer on 24.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import "NSString+URLHelper.h"
#import "NSData_Base64Extensions.h"

@implementation NSString (URLHelper)

- (NSString *)URLQuery; {
	NSRange questionMark = [self rangeOfString:@"?" options:NSBackwardsSearch];
	if (questionMark.location == NSNotFound) {
		return nil;
	}
	
	return [self substringFromIndex: questionMark.location + 1]; 
}

- (NSString *)stringByRemovingQuery; {
	NSRange questionMark = [self rangeOfString:@"?" options:NSBackwardsSearch];
	if (questionMark.location == NSNotFound) {
		return self;
	}
	
	return [self substringToIndex: questionMark.location]; 
}

- (NSString *)stringByAppendingQuery: (NSString *)query {
	return [NSString stringWithFormat: @"%@?%@", self, query];
}

- (NSString *)urlEncodeValue {
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
	return [result autorelease];
}

+ (NSString*) stringWithUUID {
    CFUUIDRef	uuidObj = CFUUIDCreate(nil);//create a new UUID
    //get the string representation of the UUID
    NSString *uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    
	return [uuidString autorelease];
}

- (NSData *)sha256 {
	unsigned char hashedChars[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256([self UTF8String],
			  [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding], 
			  hashedChars);
	NSData * hashedData = [NSData dataWithBytes:hashedChars length:CC_SHA256_DIGEST_LENGTH];
    NSLog(@"sha256 %@", [hashedData hexString]);

    
	return hashedData;
}

- (NSData *)sha1 {
    unsigned char hashedChars[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1([self UTF8String],
            [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding], 
			  hashedChars);
	NSData * hashedData = [NSData dataWithBytes:hashedChars length:CC_SHA1_DIGEST_LENGTH];
    NSLog(@"sha1 %@", [hashedData hexString]);
    NSLog(@"sha1 %@", hashedData);
	
	return hashedData;
}

@end
