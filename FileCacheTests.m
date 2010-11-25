//
//  FileCacheTests.m
//  HoccerAPI
//
//  Created by Robert Palmer on 25.11.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <GHUnitIOS/GHUnitIOS.h>
#import "HCFileCache.h"

@interface FileCacheTests : GHAsyncTestCase {
	HCFileCache *fileCache;
}

@end


@implementation FileCacheTests

- (void)setUp {
	fileCache = [[HCFileCache alloc] initWithApiKey:@"f7f3b8b0dacc012de22a00176ed99fe3" secret:@"W5AeluYT7aOo9g0O9k9o2Iq1F2Y="];
}

- (void)testUploadingFile {
	NSData *data = [@"Hallo World" dataUsingEncoding:NSUTF8StringEncoding];
	
	[fileCache cacheData: data forTimeInterval: 30];
	[self runForInterval: 3];
}


@end
