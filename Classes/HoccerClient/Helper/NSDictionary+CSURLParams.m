//
//  NSDictionary+CSURLParams.m
//  HoccerAPI
//
//  Created by Robert Palmer on 24.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "NSDictionary+CSURLParams.h"
#import "NSString+URLHelper.h"


@implementation NSDictionary (CSURLParams)

+ (id)dictionaryWithURLParams: (NSString *)paramsString {
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	
	NSArray *keyValuePairs = [paramsString componentsSeparatedByString:@"&"];
	for (NSString *keyValuePair in keyValuePairs) {
		NSArray *splited = [keyValuePair componentsSeparatedByString:@"="];
		[params setObject:[splited objectAtIndex:1] forKey:[splited objectAtIndex:0]];
	}
	
	return params;
}

- (NSString *)URLParams {
	NSMutableArray *array = [NSMutableArray array];
	for (NSString *key in self) {
		NSString *value = [self objectForKey:key];
		NSString *keyValues = [NSString stringWithFormat:@"%@=%@", key, [value urlEncodeValue]];
		[array addObject:keyValues];
	}
	
	return [array componentsJoinedByString:@"&"];
}

@end