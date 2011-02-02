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
//  HoccerTests.m
//  HoccerAPI
//
//  Created by Robert Palmer on 09.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <GHUnitIOS/GHUnitIOS.h>
#import "SandboxKeys.h"
#import "Hoccer.h"
#import "MockedLocationController.h"


#define HOCCER_CLIENT_ID @"hoccerClientUri" 

@interface MockedDelegate : NSObject <HCLinccerDelegate>
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

- (void)linccerDidRegister: (HCLinccer *)hoccer {
	didRegisterCalls += 1;
}

- (void)linccer: (HCLinccer *)hoccer didSendData: (NSArray *)info {
	didSendDataCalls += 1;
}

- (void)linccer: (HCLinccer *)hoccer didReceiveData: (NSArray *)data {
	didReceiveDataCalls += 1;
	_data = [data retain];
}

- (void)linccer: (HCLinccer *)hoccer didFailWithError: (NSError *)error {
	didFailWithErrorCalls += 1;
	_error = [error retain];
}

- (void) dealloc {
	[_error release];
	[_data release];
	
	[super dealloc];
}

@end

@interface HCLinccer (TestEnvironment)
- (void)setTestEnvironment;
@end

@implementation HCLinccer (TestEnvironment) 
- (void)setTestEnvironment {
	[environmentController release];
	
	environmentController = [[MockedLocationController alloc] init];
	
	[self environmentManagerDidUpdateEnvironment:self.environmentController];
}
@end


@interface HCClientTests : GHAsyncTestCase {
	HCLinccer *hoccer;	
	MockedDelegate *mockedDelegate;
}

- (void)cleanupUserDefaults;

@end


@implementation HCClientTests

- (void)setUp {
	[self cleanupUserDefaults];
	
	mockedDelegate = [[MockedDelegate alloc] init]; 
	hoccer = [[HCLinccer alloc] initWithApiKey:SANDBOX_APIKEY secret:SANDBOX_SECRET sandboxed: YES];
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
	[hoccer send:payload withMode:HCTransferModeOneToOne];
	[self runForInterval:3];
	[hoccer disconnect];
	[self runForInterval:1];
	
	GHAssertEquals(1, mockedDelegate.didFailWithErrorCalls, @"should have failed");	
}

- (void)testLonleyReceive {
	[self runForInterval:1];
	[hoccer receiveWithMode:HCTransferModeOneToOne];
	[self runForInterval:3];
	[hoccer disconnect];
	[self runForInterval:1];
	
	GHAssertEquals(mockedDelegate.didFailWithErrorCalls, 1, @"should have failed");
	GHAssertEquals([mockedDelegate.error code], HoccerNoSenderError, @"should have failed with no sender error");
}

- (void)testSendAndReceive {
	MockedDelegate *mockedDelegate2 = [[MockedDelegate alloc] init]; 
	HCLinccer *hoccer2 = [[HCLinccer alloc] initWithApiKey:SANDBOX_APIKEY secret:SANDBOX_SECRET sandboxed: YES];
	[hoccer2 setTestEnvironment];
	hoccer2.delegate = mockedDelegate2;
	
	[self runForInterval:2];
	
	NSDictionary *payload = [NSDictionary dictionaryWithObject:@"API3" forKey:@"Hello"];
	[hoccer receiveWithMode:HCTransferModeOneToOne];
	[hoccer2 send:payload withMode:HCTransferModeOneToOne];

	[self runForInterval:3];

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
	[hoccer disconnect];
}


- (void)testPassAndDistributeDoNotPair {
	MockedDelegate *mockedDelegate2 = [[MockedDelegate alloc] init]; 
	HCLinccer *hoccer2 = [[HCLinccer alloc] initWithApiKey:SANDBOX_APIKEY secret:SANDBOX_SECRET sandboxed: YES];
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

- (void)testCollisions {
	MockedDelegate *mockedDelegate2 = [[MockedDelegate alloc] init]; 
	HCLinccer *hoccer2 = [[HCLinccer alloc] initWithApiKey:SANDBOX_APIKEY secret:SANDBOX_SECRET sandboxed: YES];
	[hoccer2 setTestEnvironment];
	hoccer2.delegate = mockedDelegate2;

	MockedDelegate *mockedDelegate3 = [[MockedDelegate alloc] init]; 
	HCLinccer *hoccer3 = [[HCLinccer alloc] initWithApiKey:SANDBOX_APIKEY secret:SANDBOX_SECRET sandboxed: YES];
	[hoccer3 setTestEnvironment];
	hoccer3.delegate = mockedDelegate3;
	
	[self runForInterval:1];
	
	NSDictionary *payload = [NSDictionary dictionaryWithObject:@"API3" forKey:@"Hello"];
	
	[hoccer receiveWithMode:HCTransferModeOneToOne];
	[hoccer2 send:payload withMode:HCTransferModeOneToOne];
	[hoccer3 send:payload withMode:HCTransferModeOneToOne];
	
	[self runForInterval:2];
	
	[hoccer disconnect];
	[hoccer2 disconnect];
	[hoccer3 disconnect];
	
	[self runForInterval:1];
	[(MockedLocationController *)hoccer.environmentController next];

	GHAssertEquals(mockedDelegate3.didFailWithErrorCalls, 1, @"sending should have failed");
	GHAssertEquals(mockedDelegate2.didFailWithErrorCalls, 1, @"sending should have failed");
	GHAssertEquals(mockedDelegate.didFailWithErrorCalls, 1, @"reveiving should have failed");
}



- (void)cleanupUserDefaults {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:HOCCER_CLIENT_ID];
}

@end
