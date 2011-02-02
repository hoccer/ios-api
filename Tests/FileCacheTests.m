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
//  FileCacheTests.m
//  HoccerAPI
//
//  Created by Robert Palmer on 25.11.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <GHUnitIOS/GHUnitIOS.h>
#import "SandboxKeys.h"
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

- (void)fileCache: (HCFileCache *)fileCache didReceiveResponse: (NSHTTPURLResponse *)response withDownloadedData: (NSData *)data forURI: (NSString *)uri {
	NSLog(@"received data");
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
	fileCache = [[HCFileCache alloc] initWithApiKey:SANDBOX_APIKEY secret:SANDBOX_SECRET sandboxed: YES];

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
	// GHAssertEquals([fileCacheDelegate.downloadedPercentage intValue], 1, 
	//			   [NSString stringWithFormat: @"should have downloaded up to 1, but was %@", fileCacheDelegate.downloadedPercentage]);
	
	[fileCache load:fileCacheDelegate.uploadPath];
	[self runForInterval: 2];
	
	
	GHAssertNil(fileCacheDelegate.error, @"");
	NSString *received = [[[NSString alloc] initWithData:fileCacheDelegate.receivedData encoding:NSUTF8StringEncoding] autorelease];
	GHAssertEqualStrings(received, @"Hallo World", @"");
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
	[fileCache load:@"http://filecache.hoccer.com/sdfghjkl.jpg"];
	[self runForInterval:2];
	GHAssertNotNil(fileCacheDelegate.error, @"should have received an error");
}


@end
