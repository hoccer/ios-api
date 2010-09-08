//
//  WifiScannerDelegate.h
//  Hoccer
//
//  Created by Robert Palmer on 19.04.10.
//  Copyright 2010 Art+Com AG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WifiScanner;

@protocol WifiScannerDelegate <NSObject>

@optional
- (void)wifiScannerDidUpdateBssids: (WifiScanner *)scanner;


@end
