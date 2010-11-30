//
//  FileCacheTests.m
//  HoccerAPI
//
//  Created by Robert Palmer on 25.11.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <GHUnitIOS/GHUnitIOS.h>
#import "HCFileCache.h"


@interface MockedFileCacheDelegate : NSObject <HCFileCacheDelegate> {

	
	NSNumber *downloadedPercentage;
	NSString *downloadedURI;
}

@property (retain, nonatomic) NSString *uploadPath;

@property (retain, nonatomic) NSNumber *downloadedPercentage;
@property (retain, nonatomic) NSString *downloadURI;
@property (retain, nonatomic) NSData *receivedData;
@property (retain, nonatomic) NSError *error;

@end

@implementation MockedFileCacheDelegate
@synthesize uploadPath;
@synthesize downloadedPercentage, downloadURI;
@synthesize receivedData;
@synthesize error;

- (void) fileCache:(HCFileCache *)fileCache didUploadFileToURI:(NSString *)path {
	self.uploadPath = path;
}

- (void)fileCache: (HCFileCache *)fileCache didUpdateProgress: (NSNumber *)progress forURI: (NSString *)uri {
	NSLog(@"did update progress");
	self.downloadedPercentage = progress;
	self.downloadURI = uri;
}

- (void) fileCache:(HCFileCache *)fileCache didDownloadData: (NSData *)data forURI: (NSString *)uri {
	self.receivedData = data;
}


- (void) fileCache:(HCFileCache *)fileCache didFailWithError:(NSError *)aError forURI:(NSString *)uri {
	self.error = aError;
}

- (void) dealloc {
	[uploadPath release];
	[downloadedPercentage release];
	[downloadURI release];
	
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
	fileCache.delegate = nil;
	[fileCache release]; fileCache = nil;
	[fileCacheDelegate release]; fileCacheDelegate = nil;
}

- (void)testUploadingFile {
	NSData *data = [@"Hallo World" dataUsingEncoding:NSUTF8StringEncoding];
	
	[fileCache cacheData: data withFilename: @"word.txt" forTimeInterval: 30];
	[self runForInterval: 2];
	
	GHAssertNotNil(fileCacheDelegate.uploadPath, @"upload should return an upload path, but was nil");
	GHAssertEquals([fileCacheDelegate.downloadedPercentage intValue], 1, 
				   [NSString stringWithFormat: @"should have downloaded up to 1, but was %@", fileCacheDelegate.downloadedPercentage]);
	
	[fileCache load:fileCacheDelegate.uploadPath];
	[self runForInterval: 2];
}

- (void)testAbortingUpload {
	NSData *data = [@"Hallo Welt" dataUsingEncoding:NSUTF8StringEncoding];
	NSString *uploadId = [fileCache cacheData:data withFilename:@"word.txt" forTimeInterval:30];
	[fileCache cancelTransferWithURI:uploadId];

	[self runForInterval:2];
	GHAssertEquals([fileCacheDelegate.downloadedPercentage intValue], 0, 
				   [NSString stringWithFormat: @"should have downloaded 0\%, but was %@", fileCacheDelegate.downloadedPercentage]);
}

- (void)testError {
	[fileCache load:@"http://www.sdfghjklaösdfjk.com"];
	[self runForInterval:2];
	GHAssertNotNil(fileCacheDelegate.error, @"should have received an error");
}


@end
