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
//  WifiScanner.h
//  Hoccer
//
//  Created by Robert Palmer on 27.01.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
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
    BOOL justOwnInterface;
    id ifInfo;
	
	id <WifiScannerDelegate> delegate;
}

@property (readonly) NSArray *bssids;
@property (nonatomic, retain) NSArray *scannedNetworks;
@property (nonatomic, assign) id <WifiScannerDelegate> delegate;
@property (nonatomic, assign) BOOL justOwnInterface;
@property (nonatomic, retain) id ifInfo;

+ (WifiScanner *)sharedScanner;
- (void)scanNetwork;

- (NSString *)localIpAddress;

@end
