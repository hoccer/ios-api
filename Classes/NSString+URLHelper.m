//
//  NSString+URLHelper.m
//  HoccerAPI
//
//  Created by Robert Palmer on 24.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "NSString+URLHelper.h"


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
    
	[uuidString autorelease];
	return [uuidString stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

@end
