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
#import "MockedLocationController.h"

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
@property (readonly) NSData *data;

@end

@implementation MockedDelegate

@synthesize didRegisterCalls, didSendDataCalls, 
			didReceiveDataCalls, didFailWithErrorCalls;
@synthesize data = _data;

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


@interface Hoccer (TestEnvironment)
- (void)setTestEnvironment;
@end

@implementation Hoccer (TestEnvironment) 
- (void)setTestEnvironment {
	[environmentController release];
	
	environmentController = [[MockedLocationController alloc] init];
}
@end



@implementation HoccerTests

- (void)setUp {
	mockedDelegate = [[MockedDelegate alloc] init]; 
	hoccer = [[Hoccer alloc] init];
	[hoccer setTestEnvironment];
	hoccer.delegate = mockedDelegate;
}


- (void)tearDown {
	[mockedDelegate release];
	
	[(MockedLocationController *)hoccer.environmentController next];
	[hoccer release];
}

- (void)testHoccerClientRegisters {
	[self runForInterval:1];
	[hoccer disconnect];
	[self runForInterval:1];

	GHAssertEquals(mockedDelegate.didRegisterCalls, 1, @"should have registered");
}

- (void)testLonleySend {
	[self runForInterval:1];
	[hoccer send:[@"{\"Hallo\": \"Peter\"}" dataUsingEncoding:NSUTF8StringEncoding] withMode:@"distribute"];
	[self runForInterval:2];
	[hoccer disconnect];
	[self runForInterval:1];
	
	GHAssertEquals(1, mockedDelegate.didFailWithErrorCalls, @"should have failed");	
}

- (void)testLonleyReceive {
	[self runForInterval:1];
	[hoccer receiveWithMode:@"distribute"];
	[self runForInterval:2];
	[hoccer disconnect];
	[self runForInterval:1];
	
	GHAssertEquals(1, mockedDelegate.didFailWithErrorCalls, @"should have failed");
}

- (void)testSendAndReceive {
//	[self runForInterval:1];

	MockedDelegate *mockedDelegate2 = [[MockedDelegate alloc] init]; 
	Hoccer *hoccer2 = [[Hoccer alloc] init];
	[hoccer2 setTestEnvironment];
	hoccer2.delegate = mockedDelegate2;
	
	[self runForInterval:1];
	
	NSString *payload = @"{\"Hallo\":\"API3\"}";
	[hoccer receiveWithMode:@"distribute"];
	[hoccer2 send:[payload dataUsingEncoding:NSUTF8StringEncoding] withMode:@"distribute"];

	[self runForInterval:7];

	NSString *received = [[[NSString alloc] initWithData:mockedDelegate.data encoding:NSUTF8StringEncoding] autorelease];
	
	[hoccer disconnect];
	[hoccer2 disconnect];
	[self runForInterval:1];
	[(MockedLocationController *)hoccer.environmentController next];
	
	GHAssertEquals(1, mockedDelegate.didSendDataCalls, @"should have send some data");
	GHAssertEquals(1, mockedDelegate2.didReceiveDataCalls, @"should have received some data");
	
	NSString *expected = [NSString stringWithFormat:@"[%@]", payload];
	GHAssertEqualStrings(expected, received, @"should have received payload");
}

- (void)testReceivingWithoutPreconditions {
	[hoccer receiveWithMode:@"distribute"];
	GHAssertEquals(1, mockedDelegate.didFailWithErrorCalls, @"should have failed");
}




@end
