//
//  HoccerTests.m
//  HoccerAPI
//
//  Created by Robert Palmer on 09.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <GHUnitIOS/GHUnitIOS.h>
#import "Hoccer.h"
#import "HoccerDelegate.h"

@interface MockedDelegate : NSObject <HoccerDelegate>
{
	NSInteger didRegisterCalls, didSendDataCalls, 
			  didReceiveDataCalls, didFailWithErrorCalls;
	NSError *_error;
	NSData *_data; 
}
@property (assign) NSInteger didRegisterCalls;
@property (assign) NSInteger didSendDataCalls;
@property (assign) NSInteger didReceiveDataCalls;
@property (assign) NSInteger didFailWithErrorCalls;

@end

@implementation MockedDelegate

@synthesize didRegisterCalls, didSendDataCalls, 
			didReceiveDataCalls, didFailWithErrorCalls;

- (void)hoccerDidRegister: (Hoccer *)hoccer {
	didRegisterCalls += 1;
}

- (void)hoccerDidSendData: (Hoccer *)hoccer {
	didSendDataCalls += 1;
}

- (void)hoccer: (Hoccer *)hoccer didReceiveData: (NSData *)data {
	didReceiveDataCalls += 1;
	_data = data;
}

- (void)hoccer: (Hoccer *)hoccer didFailWithError: (NSError *)error {
	didFailWithErrorCalls += 1;
	_error = error;
}

@end



@interface HoccerTests : GHAsyncTestCase {
	Hoccer *hoccer;	
	MockedDelegate *mockedDelegate;
}


@end


@implementation HoccerTests

- (void)setUp {
	mockedDelegate = [[MockedDelegate alloc] init]; 
	hoccer = [[Hoccer alloc] init];
	hoccer.delegate = mockedDelegate;
}


- (void)tearDown {
	[mockedDelegate release];
	[hoccer release];
}

- (void)testHoccerClientRegisters {
	[self runForInterval:1];
	GHAssertEquals(1, mockedDelegate.didRegisterCalls, @"should have registered");
}

@end
