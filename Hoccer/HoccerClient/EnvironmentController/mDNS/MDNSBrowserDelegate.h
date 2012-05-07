//
//  MDNSBrowserDelegate.h
//  Hoccer
//
//  Created by Philip Brechler on 30.04.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//


@class MDNSBrowser;

@protocol MDNSBrowserDelegate <NSObject>

@optional
- (void)mdnsBrowserDidUpdateDiscoveries: (MDNSBrowser *)browser;
@end
