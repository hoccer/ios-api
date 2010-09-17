//
//  WifiScanner.h
//  Hoccer
//
//  Created by Robert Palmer on 27.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WifiScannerDelegate.h"

@interface WifiScanner : NSObject {
	void* wifiHandle;
	
	int (*open)(void *);
	int (*bind)(void *, NSString*);
	int (*close)(void *);
	int (*scan)(void *, NSArray **, void*);
	
	NSArray *scannedNetworks;
	BOOL repeat;
	
	id <WifiScannerDelegate> delegate;
}

@property (readonly) NSArray *bssids;
@property (nonatomic, retain) NSArray *scannedNetworks;
@property (nonatomic, assign) id <WifiScannerDelegate> delegate;

+ (WifiScanner *)sharedScanner;
- (void)scanNetwork;

- (NSString *)localIpAddress;

@end
