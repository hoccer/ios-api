//
//  NSStringURLHelperTests.m
//  HoccerAPI
//
//  Created by Robert Palmer on 24.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <GHUnitIOS/GHUnitIOS.h>
#import "NSString+URLHelper.h"

@interface NSStringURLHelperTests : GHTestCase {
	
}

@end

@implementation NSStringURLHelperTests

- (void)testURLQuery {
	NSString *uri = @"/query?hallo=welt";
	GHAssertEqualStrings([uri URLQuery], @"hallo=welt", nil);
}

- (void)testInvalidURLQuery {
	NSString *uri = @"/query";
	GHAssertNil([uri URLQuery], nil);
}

- (void)testRemovingQuery {
	NSString *uri = @"/query?hallo=welt";
	GHAssertEqualStrings([uri stringByRemovingQuery], @"/query", nil);
}

- (void)testAppendingQuery {
	NSString *uri = @"/query";
	GHAssertEqualStrings([uri stringByAppendingQuery:@"hallo=welt"], @"/query?hallo=welt", nil);
}



@end
