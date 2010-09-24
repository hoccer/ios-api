//
//  NSDictionaryURLParamsTests.m
//  HoccerAPI
//
//  Created by Robert Palmer on 24.09.10.
//  Copyright Robetr Palmer. All rights reserved.
//

#import <GHUnitIOS/GHUnitIOS.h>
#import "NSDictionary+CSURLParams.h"

@interface NSDictionaryURLParamsTests : GHTestCase
{
	
}
@end



@implementation NSDictionaryURLParamsTests

- (void)testDictionaryFromURLParams {
	NSString *paramString = @"signature=987987&apiKey=123123";
	
	NSDictionary *params = [NSDictionary dictionaryWithURLParams: paramString];
	GHAssertEquals((NSInteger)[params count], 2, @"should have 2 elements"); 
	GHAssertEqualStrings([params objectForKey:@"apiKey"], @"123123", @"key should be parsed right");
	GHAssertEqualStrings([params objectForKey:@"signature"], @"987987", @"key should be parsed right");
}


- (void)testURLParamsFromDictionary {
	NSDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							@"987987", @"signature",
							@"123123", @"apiKey", nil];
	
	NSString *paramsString = [params URLParams];
	GHAssertEqualStrings(paramsString, @"apiKey=123123&signature=987987", nil);
}

@end
