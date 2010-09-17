//
//  WifiScanner.m
//  Hoccer
//
//  Created by Robert Palmer on 27.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WifiScanner.h"

#import <dlfcn.h>
#import <ifaddrs.h>
#import <arpa/inet.h>



static WifiScanner *wifiScannerInstance;

@implementation WifiScanner

@synthesize scannedNetworks;
@synthesize delegate;

+ (WifiScanner *)sharedScanner {
	if (wifiScannerInstance == nil) {
		wifiScannerInstance = [[WifiScanner alloc] init];
	}
	
	return wifiScannerInstance;
}

- (id) init {
#if TARGET_IPHONE_SIMULATOR 
	return [super init];
#else 
	self = [super init];
	if (self != nil) {
		void* libHandle = dlopen("/System/Library/SystemConfiguration/WiFiManager.bundle/WiFiManager", RTLD_LAZY);

		open = dlsym(libHandle, "Apple80211Open");
		bind = dlsym(libHandle, "Apple80211BindToInterface");
		close = dlsym(libHandle, "Apple80211Close");
		scan  = dlsym(libHandle, "Apple80211Scan");
		
		open(&wifiHandle);
		bind(wifiHandle, @"en0");
		
		repeat = YES;
		[self scanNetwork];
	}
	
	return self;
#endif
}

- (void)scanNetwork {
	[NSThread detachNewThreadSelector:@selector(scan) toTarget:self withObject:nil];
	
	if (repeat) {
		[NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(scanNetwork) userInfo:nil repeats:NO];
	}
}

- (void)stopScanning {
	repeat = NO;
}

- (void)setScannedNetworks:(NSArray *)networks {
	if (scannedNetworks != networks) {
		[scannedNetworks release];
		scannedNetworks = [networks copy];
	} 
	
	if ([delegate respondsToSelector:@selector(wifiScannerDidUpdateBssids:)]) {
		[delegate wifiScannerDidUpdateBssids: self]; 
	}
}

- (NSArray *)bssids 
{
	if (scannedNetworks == nil) {
		return nil;
	}
	
	NSMutableArray *bssids = [[NSMutableArray alloc] init];
	for (NSDictionary *wifiSpot in scannedNetworks) {
		[bssids addObject: [wifiSpot valueForKey:@"BSSID"]];
	}
	
	return [bssids autorelease];
}

- (void)scan {
	NSDictionary *parameters = [[NSDictionary alloc] init];
	NSArray *newScanNetworks = nil;
	scan(wifiHandle, &newScanNetworks, parameters);
	[parameters release];
	
	[self performSelectorOnMainThread:@selector(setScannedNetworks:) withObject:newScanNetworks waitUntilDone:NO];
	[newScanNetworks release];
}

- (void) dealloc {
	[scannedNetworks release];
	[super dealloc];
}

- (NSString *)localIpAddress; {
	NSString *address = @"error";
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	
	// retrieve the current interfaces - returns 0 on success
	success = getifaddrs(&interfaces);
	if (success == 0)
	{
		// Loop through linked list of interfaces
		temp_addr = interfaces;
		while(temp_addr != NULL)
		{
			if(temp_addr->ifa_addr->sa_family == AF_INET)
			{
				// Check if interface is en0 which is the wifi connection on the iPhone
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
				{
					// Get NSString from C String
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				}
			}
			
			temp_addr = temp_addr->ifa_next;
		}
	}
	
	// Free memory
	freeifaddrs(interfaces);
	
	return address;
}

@end
