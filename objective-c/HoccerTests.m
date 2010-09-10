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

//- (void)testHoccerClientRegisters {
//	[self runForInterval:1];
//	GHAssertEquals(mockedDelegate.didRegisterCalls, 1, @"should have registered");
//}

- (void)testLonleySend {
	[self runForInterval:1];
	[hoccer send:[@"{\"Hallo\": \"Peter\"}" dataUsingEncoding:NSUTF8StringEncoding] withMode:@"distribute"];
	[self runForInterval:5];
	
	GHAssertEquals(1, mockedDelegate.didFailWithErrorCalls, @"should have failed");	
}

//- (void)testLonleyReceive {
//	[self runForInterval:1];
//	[hoccer receiveWithMode:@"distribute"];
//	[self runForInterval:2];
//	
//	GHAssertEquals(1, mockedDelegate.didFailWithErrorCalls, @"should have failed");
//}
//
//- (void)testSendAndReceive {
//	MockedDelegate *mockedDelegate2 = [[MockedDelegate alloc] init]; 
//	Hoccer *hoccer2 = [[Hoccer alloc] init];
//	hoccer2.delegate = mockedDelegate2;
//	
//	[self runForInterval:1];
//	
//	[hoccer receiveWithMode:@"distribute"];
//	[hoccer2 send:[@"{\"Hallo\": \"API3\"}" dataUsingEncoding:NSUTF8StringEncoding] withMode:@"distribute"];
//	
//	[self runForInterval:4];
//	
//	GHAssertEquals(1, mockedDelegate2.didSendDataCalls, @"should have send data");
//	GHAssertEquals(1, mockedDelegate2.didReceiveDataCalls, @"should have send data");
//}


@end
