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
//  HCGeostorageTests.m
//  HoccerAPI
//
//  Created by Robert Palmer on 15.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <GHUnitIOS/GHUnitIOS.h>
#import <MapKit/MapKit.h>
#import "HCGeoStorage.h"
#import "HCGeoStorageDelegate.h"
#import "MockedLocationController.h"


static NSMutableArray *allRecordIds;

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

- (id) init
{
	self = [super init];
	if (self != nil) {
		if (allRecordIds == nil) {
			allRecordIds = [[NSMutableArray alloc] init];
		} 
	}
	return self;
}


- (void)geostorage: (HCGeoStorage *)geoStorage didFinishStoringWithId: (NSString *)urlId {
	[allRecordIds addObject: urlId];
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

- (void)createRecordAtLong: (CLLocationDegrees)longituge lat: (CLLocationDegrees) latitude properties: (NSDictionary *)dict;
- (void)deleteRecords;

@end

@implementation HCGeoStorageTests

- (void)setUp {
	storage = [[HCGeoStorage alloc] initWithApiKey:@"d9e26760ad39012dc9cf00176ed99fe3" secret: @"3t/ULFbjL01v7VdNedAOjIjNOfM="];
	[storage setTestEnvironment];
	mockedDelegate = [[MockedGeoStorageDelegate alloc] init];
	storage.delegate = mockedDelegate;
}

- (void)tearDown {
	[self deleteRecords];
	[storage release];
	[mockedDelegate release];
}

- (void)testStoringData {
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"wu tang clan ain't nothing to fuck wit" forKey:@"note"];
	CLLocationCoordinate2D coords; coords.latitude = 12; coords.longitude = 12;
	
	[storage storeProperties:dict atLocation:coords forTimeInterval:30];
	[self runForInterval:2];
	GHAssertNotNil(mockedDelegate.url, @"should have returned an url");
	
	[storage searchAtLocation:coords radius:100];
	[self runForInterval:2];	
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 1, @"should have found one item");
	
	[storage deleteRecordWithId: mockedDelegate.url];
	[self runForInterval:1];
	mockedDelegate.items = nil;
	[storage searchAtLocation:coords radius:100];
	[self runForInterval:2];
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 0, @"should have deleted item");
}


- (void)testExpiration {
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"wu tang clan ain't nothin' to fuck wit" forKey:@"note"];
	CLLocationCoordinate2D coords; coords.latitude = 12; coords.longitude = 12;
	
	[storage storeProperties:dict atLocation:coords forTimeInterval:2];
	[self runForInterval:3];
	GHAssertNotNil(mockedDelegate.url, @"should have returned an url");
	
	[storage searchAtLocation:coords radius:100];
	[self runForInterval:2];	
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 0, @"item should be expired");
}

- (void)testSearchNearby {
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"bada bing" forKey:@"note"];
	
	[storage storeProperties: dict];
	[self runForInterval:2];
	
	[storage searchNearby];
	[self runForInterval:2];
	
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 1, @"item should be expired");
}

- (void)testSearchNotInRadius {
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"wu tang clan ain't nothin' to fuck wit" forKey:@"note"];
	CLLocationCoordinate2D coords; coords.latitude = 12; coords.longitude = 12;
	[storage storeProperties:dict atLocation:coords forTimeInterval:30];
	[self runForInterval:3];
	GHAssertNotNil(mockedDelegate.url, @"should have returned an url");
	
	coords.latitude = 15; coords.longitude = 15;
	[storage searchAtLocation:coords radius:100];
	[self runForInterval:2];
	
	GHAssertNotNil(mockedDelegate.items, @"items should not be nil");
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 0, @"item should be expired");
}

- (void)testSearchInRegion {
	[self createRecordAtLong:12.5 lat:11.5 properties:nil];
	[self createRecordAtLong:11.5 lat:12.5 properties:nil];
	[self createRecordAtLong:10.5 lat:11.5 properties:nil];
	[self runForInterval:2];
	
	CLLocationCoordinate2D coords; coords.latitude = 12; coords.longitude = 12;
	MKCoordinateRegion region; region.center = coords; region.span = MKCoordinateSpanMake(1, 1);
	[storage searchInRegion:region];
	[self runForInterval:1];
	
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 2, @"should return all records in region");
}

- (void)testSearchInProperties {
	[self createRecordAtLong:12 lat:12 properties:[NSDictionary dictionaryWithObject:@"beastie boys" forKey:@"layer"]];
	[self createRecordAtLong:12 lat:12 properties:[NSDictionary dictionaryWithObject:@"beastie boys" forKey:@"layer"]];
	[self createRecordAtLong:12 lat:12 properties:[NSDictionary dictionaryWithObject:@"wu tang" forKey:@"layer"]];
	[self runForInterval:2];
	
	CLLocationCoordinate2D coords; coords.latitude = 12; coords.longitude = 12;
	MKCoordinateRegion region; region.center = coords; region.span = MKCoordinateSpanMake(1, 1);
	
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"beastie boys" forKey:@"layer"];
	
	[storage searchInRegion:region withConditions: dict];
	[self runForInterval:1];
	
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 2, @"should return all record with layer");
}

- (void)testInvalidAuthentification {
	HCGeoStorage *s = [[HCGeoStorage alloc] initWithApiKey:@"aaaaa" secret: @"12346"];
	[s setTestEnvironment];
	s.delegate = mockedDelegate;

	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"wu tang clan ain't nothing to fuck wit" forKey:@"note"];
	CLLocationCoordinate2D coords; coords.latitude = 12; coords.longitude = 12;
	
	[s storeProperties:dict atLocation:coords forTimeInterval:10];
	[self runForInterval:2];
	
	GHAssertNotNil(mockedDelegate.error, @"should have returned error");
	GHAssertEquals([mockedDelegate.error code], 401, nil);
}

- (void)testAccountDestinction {
	HCGeoStorage *storage2 = [[HCGeoStorage alloc] initWithApiKey:@"c43c98f0ad41012dc9cf00176ed99fe3" 
														   secret: @"I+8cvWOBnhBsFIdxZM26diyvaeo="];
	[storage2 setTestEnvironment];
	storage2.delegate = mockedDelegate;
	
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"wu tang clan ain't nothing to fuck wit" forKey:@"note"];
	CLLocationCoordinate2D coords; coords.latitude = 12; coords.longitude = 12;
	
	[storage2 storeProperties:dict atLocation:coords forTimeInterval:10];
	[self runForInterval:2];
	GHAssertNotNil(mockedDelegate.url, nil);
	
	
	[storage searchAtLocation:coords radius:50];
	[self runForInterval:2];
	 
	GHAssertNotNil(mockedDelegate.items, @"should have returned error");
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 0, nil);
	
}



- (void)testSearchInPropertiesNearby {
	[storage storeProperties:[NSDictionary dictionaryWithObject:@"beastie boys" forKey:@"layer"]];
	[storage storeProperties:[NSDictionary dictionaryWithObject:@"beastie boys" forKey:@"layer"]];
	[storage storeProperties:[NSDictionary dictionaryWithObject:@"wu tang" forKey:@"layer"]];
	[self runForInterval:2];
	
	CLLocationCoordinate2D coords; coords.latitude = 12; coords.longitude = 12;
	MKCoordinateRegion region; region.center = coords; region.span = MKCoordinateSpanMake(1, 1);
	
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"wu tang" forKey:@"layer"];
	
	[storage searchNearbyWithConditions: dict];
	[self runForInterval:1];
	
	GHAssertEquals((NSInteger)[mockedDelegate.items count], 1, @"should return all record with correct layer");
}


- (void)createRecordAtLong: (CLLocationDegrees)longituge lat: (CLLocationDegrees) latitude properties: (NSDictionary *)dict {
	CLLocationCoordinate2D coords; 
	coords.latitude = latitude; 
	coords.longitude = longituge;
	
	[storage storeProperties:dict atLocation:coords forTimeInterval:30];
}


- (void)deleteRecords {
	for (NSString *recordId in allRecordIds) {
		[storage deleteRecordWithId: recordId];
	}
	[allRecordIds removeAllObjects];
	
	[self runForInterval:2];
}

@end