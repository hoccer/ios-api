//
//  FileCacheTests.m
//  HoccerAPI
//
//  Created by Robert Palmer on 25.11.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <GHUnitIOS/GHUnitIOS.h>
#import "HCFileCache.h"


@interface MockedFileCacheDelegate : NSObject <HCFileCacheDelegate>
{
	NSString *uploadPath;
}

@property (retain, nonatomic) NSString *uploadPath;
@end

@implementation MockedFileCacheDelegate
@synthesize uploadPath;


- (void) fileCache:(HCFileCache *)fileCache didUploadFileToPath:(NSString *)path {
	self.uploadPath = path;
}

- (void) dealloc {
	[uploadPath release];
	[super dealloc];
}

@end


@interface FileCacheTests : GHAsyncTestCase <HCFileCacheDelegate> {
	HCFileCache *fileCache;
	MockedFileCacheDelegate *fileCacheDelegate;
}

@end


@implementation FileCacheTests

- (void)setUp {
	fileCacheDelegate = [[MockedFileCacheDelegate alloc] init];
	fileCache = [[HCFileCache alloc] initWithApiKey:@"f7f3b8b0dacc012de22a00176ed99fe3" secret:@"W5AeluYT7aOo9g0O9k9o2Iq1F2Y="];

	fileCache.delegate = fileCacheDelegate;
}

- (void)tearDown {
	[fileCache release]; fileCache = nil;
	[fileCacheDelegate release]; fileCacheDelegate = nil;
}

- (void)testUploadingFile {
	NSData *data = [@"Hallo World" dataUsingEncoding:NSUTF8StringEncoding];
	
	[fileCache cacheData: data forTimeInterval: 30];
	[self runForInterval: 2];
	
	GHAssertNotNil(fileCacheDelegate.uploadPath, @"upload should return an upload path, but was nil");
	
	[fileCache load:fileCacheDelegate.uploadPath];
	[self runForInterval: 2];
}


-(void) fileCache:(HCFileCache *)fileCache didUploadFileToPath:(NSString *)path {
	NSLog(@"uploaded to path: %@", path);
}





@end
