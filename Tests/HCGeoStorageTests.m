//
//  HCGeostorageTests.m
//  HoccerAPI
//
//  Created by Robert Palmer on 15.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <GHUnitIOS/GHUnitIOS.h>
#import "HCGeoStorage.h"
#import "HCGeoStorageDelegate.h"
#import "MockedLocationController.h"


@interface HCGeoStorage (TestEnvironment)
- (void)setTestEnvironment;
@end

@implementation HCGeoStorage (TestEnvironment) 
- (void)setTestEnvironment {
	[environmentController release];
	
	environmentController = [[MockedLocationController alloc] init];
}
@end

@interface MockedGeoStorageDelegate : NSObject <HCGeoStorageDelegate> {
	NSString *url;
	NSArray *items;
	NSError *error;
}

@property (retain) NSString *url;
@property (retain) NSArray *items;
@property (retain) NSError *error;

@end


@implementation MockedGeoStorageDelegate

@synthesize url, items, error;

- (void)geostorage: (HCGeoStorage *)geoStorage didFinishStoringWithId: (NSString *)urlId {
	self.url = urlId;
}

- (void)geostorage: (HCGeoStorage *)geoStorage didFindItems: (NSArray *)theItems {
	self.items = theItems;
}

- (void)geostorage: (HCGeoStorage *)geoStorage didFailWithError: (NSError *)theError; {
	self.error = theError;
}

- (void) dealloc {
	[url release];
	[items release];
	[error release];
	
	[super dealloc];
}


@end


@interface HCGeoStorageTests : GHAsyncTestCase {
	MockedGeoStorageDelegate *mockedDelegate;
	HCGeoStorage *storage;
}

@end

@implementation HCGeoStorageTests

- (void)setUp {
	storage = [[HCGeoStorage alloc] init];
	[storage setTestEnvironment];
	mockedDelegate = [[MockedGeoStorageDelegate alloc] init];
	storage.delegate = mockedDelegate;
}

- (void)tearDown {
	[storage release];
	[mockedDelegate release];
}

- (void)testStoringData {
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"wu tang clan ain't nothing to fuck wit" forKey:@"note"];
	CLLocationCoordinate2D coords; coords.latitude = 12; coords.longitude = 12;
	
	[storage storeDictionary:dict atLocation:coords forTimeInterval:30];
	[self runForInterval:2];
	GHAssertNotNil(mockedDelegate.url, @"should have returned an url");
	
	[storage searchAtLocation:coords radius:100];
	[self runForInterval:2];	
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 1, @"should have found one item");
	
	[storage delete: mockedDelegate.url];
	[self runForInterval:1];
	mockedDelegate.items = nil;
	[storage searchAtLocation:coords radius:100];
	[self runForInterval:2];
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 0, @"should have deleted item");
}


- (void)testExpiration {
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"wu tang clan ain't nothin' to fuck wit" forKey:@"note"];
	CLLocationCoordinate2D coords; coords.latitude = 12; coords.longitude = 12;
	
	[storage storeDictionary:dict atLocation:coords forTimeInterval:2];
	[self runForInterval:3];
	GHAssertNotNil(mockedDelegate.url, @"should have returned an url");
	
	[storage searchAtLocation:coords radius:100];
	[self runForInterval:2];	
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 0, @"item should be expired");
	
	[storage delete: mockedDelegate.url];
	[self runForInterval:1];
}

- (void)testSearchNearby {
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"bada bing" forKey:@"note"];
	
	[storage store: dict];
	[self runForInterval:2];
	
	[storage searchNearby];
	[self runForInterval:2];
	
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 1, @"item should be expired");
	
	[storage delete: mockedDelegate.url];
	[self runForInterval:1];
}

- (void)testSearchNotInRadius {
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"wu tang clan ain't nothin' to fuck wit" forKey:@"note"];
	CLLocationCoordinate2D coords; coords.latitude = 12; coords.longitude = 12;
	
	[storage storeDictionary:dict atLocation:coords forTimeInterval:2];
	[self runForInterval:3];
	GHAssertNotNil(mockedDelegate.url, @"should have returned an url");
	
	coords.latitude = 15; coords.longitude = 15;
	[storage searchAtLocation:coords radius:100];
	[self runForInterval:2];
	
	GHAssertNotNil(mockedDelegate.items, @"items should not be nil");
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 0, @"item should be expired");
	
	[storage delete: mockedDelegate.url];
	[self runForInterval:1];
	
}


@end
