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
