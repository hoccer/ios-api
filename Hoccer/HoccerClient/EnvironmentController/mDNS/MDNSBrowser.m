//
//  MDNSBrowser.m
//  Hoccer
//
//  Created by Philip Brechler on 30.04.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import "MDNSBrowser.h"

static MDNSBrowser *mdnsBrowserInstance;


@implementation MDNSBrowser 

@synthesize discoveredClients;
@synthesize delegate;
@synthesize mdnsBrowser;

+ (MDNSBrowser *)sharedBrowser {
    
    if (mdnsBrowserInstance == nil) {
		mdnsBrowserInstance = [[MDNSBrowser alloc] init];
	}
    
    return mdnsBrowserInstance;
}

- (id) init {
    self = [super init];
    
    self.mdnsBrowser = [[NSNetServiceBrowser alloc] init];
    self.mdnsBrowser.delegate = self;
    [self.mdnsBrowser searchForServicesOfType:@"_Hoccer._tcp." inDomain:@""];

    self.discoveredClients = [[NSMutableArray alloc] init];

    return self;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    NSLog(@"Found a Service");
    
    [aNetService retain];
    [aNetService setDelegate:self];
    [aNetService startMonitoring];
    [aNetService resolveWithTimeout:1];
    
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data {
    NSDictionary *aClient = [NSNetService dictionaryFromTXTRecordData:data];
    
    if ([aClient objectForKey:@"id"])
        [self.discoveredClients addObject:[[NSString alloc] initWithData:[aClient objectForKey:@"id"] encoding:NSUTF8StringEncoding]];
    
    [delegate mdnsBrowserDidUpdateDiscoveries:self];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    NSLog(@"Removed Service");
   
    
    for (int i; i < self.discoveredClients.count; i++) {
        if ([[[NSString alloc] initWithData:aNetService.TXTRecordData encoding:NSUTF8StringEncoding] isEqualToString:[self.discoveredClients objectAtIndex:i]]){
            [self.discoveredClients removeObjectAtIndex:i];
        }
    }
    
    [delegate mdnsBrowserDidUpdateDiscoveries:self];

}

@end
