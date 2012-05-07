//
//  MDNSBrowser.h
//  Hoccer
//
//  Created by Philip Brechler on 30.04.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDNSBrowserDelegate.h"

@interface MDNSBrowser : NSObject <NSNetServiceBrowserDelegate,NSNetServiceDelegate> {
    NSNetServiceBrowser *mdnsBrowser;
    NSMutableArray *discoveredClients;
    
    id <MDNSBrowserDelegate>delegate;
}

@property (nonatomic, retain)NSNetServiceBrowser *mdnsBrowser;
@property (nonatomic, retain)NSMutableArray *discoveredClients;
@property (atomic, assign) id  <MDNSBrowserDelegate> delegate;

+ (MDNSBrowser *)sharedBrowser;

@end
