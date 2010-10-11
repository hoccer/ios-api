//
//  HoccerTests.m
//  HoccerAPI
//
//  Created by Robert Palmer on 09.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <GHUnitIOS/GHUnitIOS.h>
#import "HCClient.h"
#import "HCClientDelegate.h"
#import "MockedLocationController.h"

#define HOCCER_CLIENT_URI @"hoccerClientUri" 

@interface MockedDelegate : NSObject <HCClientDelegate>
{
	NSInteger didRegisterCalls, didSendDataCalls, 
			  didReceiveDataCalls, didFailWithErrorCalls;
	NSError *_error;
	NSArray *_data; 
}

@property (assign) NSInteger didRegisterCalls;
@property (assign) NSInteger didSendDataCalls;
@property (assign) NSInteger didReceiveDataCalls;
@property (assign) NSInteger didFailWithErrorCalls;
@property (readonly) NSArray *data;
@property (readonly) NSError *error;

@end

@implementation MockedDelegate

@synthesize didRegisterCalls, didSendDataCalls, 
			didReceiveDataCalls, didFailWithErrorCalls;
@synthesize data = _data, error = _error;

- (void)clientDidRegister: (HCClient *)hoccer {
	didRegisterCalls += 1;
}

- (void)clientDidSendData: (HCClient *)hoccer {
	didSendDataCalls += 1;
}

- (void)client: (HCClient *)hoccer didReceiveData: (NSArray *)data {
	didReceiveDataCalls += 1;
	_data = [data retain];
}

- (void)client: (HCClient *)hoccer didFailWithError: (NSError *)error {
	didFailWithErrorCalls += 1;
	_error = [error retain];
}

- (void) dealloc {
	[_error release];
	[_data release];
	
	[super dealloc];
}

@end

@interface HCClient (TestEnvironment)
- (void)setTestEnvironment;
@end

@implementation HCClient (TestEnvironment) 
- (void)setTestEnvironment {
	[environmentController release];
	
	environmentController = [[MockedLocationController alloc] init];
}
@end


@interface HCClientTests : GHAsyncTestCase {
	HCClient *hoccer;	
	MockedDelegate *mockedDelegate;
}

- (void)cleanupUserDefaults;

@end


@implementation HCClientTests

- (void)setUp {
	[self cleanupUserDefaults];
	
	mockedDelegate = [[MockedDelegate alloc] init]; 
	hoccer = [[HCClient alloc] initWithApiKey:@"123456789" secret:@"secret!"];
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
	NSDictionary *payload = [NSDictionary dictionaryWithObject:@"Peter" forKey:@"Hallo"];
	[hoccer send:payload withMode:HCTransferModeOneToMany];
	[self runForInterval:2];
	[hoccer disconnect];
	[self runForInterval:1];
	
	GHAssertEquals(1, mockedDelegate.didFailWithErrorCalls, @"should have failed");	
}

- (void)testLonleyReceive {
	[self runForInterval:1];
	[hoccer receiveWithMode:HCTransferModeOneToMany];
	[self runForInterval:2];
	[hoccer disconnect];
	[self runForInterval:1];
	
	GHAssertEquals(mockedDelegate.didFailWithErrorCalls, 1, @"should have failed");
	GHAssertEquals([mockedDelegate.error code], HoccerNoSenderError, @"should have failed with no sender error");
}

- (void)testSendAndReceive {
	MockedDelegate *mockedDelegate2 = [[MockedDelegate alloc] init]; 
	HCClient *hoccer2 = [[HCClient alloc] initWithApiKey:@"123456789" secret:@"secret"];
	[hoccer2 setTestEnvironment];
	hoccer2.delegate = mockedDelegate2;
	
	[self runForInterval:1];
	
	NSDictionary *payload = [NSDictionary dictionaryWithObject:@"API3" forKey:@"Hello"];
	[hoccer receiveWithMode:HCTransferModeOneToOne];
	[hoccer2 send:payload withMode:HCTransferModeOneToOne];

	[self runForInterval:7];

	[hoccer disconnect];
	[hoccer2 disconnect];
	[self runForInterval:1];
	[(MockedLocationController *)hoccer.environmentController next];

	GHAssertEquals(mockedDelegate2.didSendDataCalls, 1, @"should have send some data");
	GHAssertEquals(mockedDelegate.didReceiveDataCalls, 1, @"should have received some data");
	
	GHAssertTrue([mockedDelegate.data count] > 0, nil);
	NSDictionary *received = [mockedDelegate.data objectAtIndex:0];

	GHAssertEqualObjects(payload, received, @"should have received payload");
}

- (void)testReceivingWithoutPreconditions {
	[hoccer receiveWithMode:HCTransferModeOneToMany];
	GHAssertEquals(1, mockedDelegate.didFailWithErrorCalls, @"should have failed");
}


- (void)testPassAndDistributeDoNotPair {
	MockedDelegate *mockedDelegate2 = [[MockedDelegate alloc] init]; 
	HCClient *hoccer2 = [[HCClient alloc] initWithApiKey:@"123456789" secret:@"secret"];
	[hoccer2 setTestEnvironment];
	hoccer2.delegate = mockedDelegate2;
	
	[self runForInterval:1];
	
	NSDictionary *payload = [NSDictionary dictionaryWithObject:@"API3" forKey:@"Hello"];
	
	[hoccer receiveWithMode:HCTransferModeOneToOne];
	[hoccer2 send:payload withMode:HCTransferModeOneToMany];
	
	[self runForInterval:7];
		
	[hoccer disconnect];
	[hoccer2 disconnect];
	[self runForInterval:1];
	[(MockedLocationController *)hoccer.environmentController next];
	
	GHAssertEquals(mockedDelegate2.didFailWithErrorCalls, 1, @"sending should have failed");
	GHAssertEquals(mockedDelegate.didFailWithErrorCalls, 1, @"reveiving should have failed");
}


- (void)cleanupUserDefaults {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:HOCCER_CLIENT_URI];
}




@end
