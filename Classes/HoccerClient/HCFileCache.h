//
//  HCFileCache.h
//  HoccerAPI
//
//  Created by Robert Palmer on 24.11.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HCFileCache;

@protocol HCFileCacheDelegate

- (void)fileCache: (HCFileCache *)fileCache didFailWithError: (NSError *)error;
- (void)fileCache: (HCFileCache *)fileCache didDownloadFile: (NSString *)path;

@end


@interface HCFileCache : NSObject {

}

- (void)send: (NSString *)filepath;
- (void)load: (NSString *)url;

@end
