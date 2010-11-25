//
//  FileCacheTests.m
//  HoccerAPI
//
//  Created by Robert Palmer on 25.11.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <GHUnitIOS/GHUnitIOS.h>
#import "HCFileCache.h"

@interface FileCacheTests : GHTestCase {
	HCFileCache *fileCache;
}

@end


@implementation FileCacheTests

- (void)setUp {
	fileCache = [[HCFileCache alloc] initWithApiKey:@"" secret:@""];
}

- (void)testUploadingFile {
	GHFail(@"fail");
}


@end
