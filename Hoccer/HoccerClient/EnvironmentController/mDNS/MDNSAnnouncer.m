//
//  MDNSAnnouncer.m
//  Hoccer
//
//  Created by Philip Brechler on 30.04.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import "MDNSAnnouncer.h"

static MDNSAnnouncer *mdnsAnnouncerInstance;


@implementation MDNSAnnouncer 

+ (MDNSAnnouncer *)sharedAnnouncer {
    if (mdnsAnnouncerInstance == nil) {
        mdnsAnnouncerInstance = [[MDNSAnnouncer alloc] init];
    }
    return mdnsAnnouncerInstance;
}

- (id)init {
    self = [super init];
    
    mdnsService = [[NSNetService alloc]initWithDomain:@"local." type:@"_Hoccer._tcp." name:[[NSUserDefaults standardUserDefaults] objectForKey:@"clientName"] port:1234];
    mdnsService.delegate = self;
    NSDictionary *clientId = [NSDictionary dictionaryWithObjectsAndKeys:[[NSUserDefaults standardUserDefaults] stringForKey:@"mdnsId"],@"id", nil];
    NSData *clientData = [NSNetService dataFromTXTRecordDictionary:clientId];
    if (![mdnsService setTXTRecordData:clientData]) {
        NSLog(@"FAIL");
    }
    return self;
}

-(void)netServiceDidPublish:(NSNetService *)sender {
    NSLog(@"We did it");
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    
    NSLog(@"Oh noes!");
}
- (void)startAnnouncing {
    
    [mdnsService publish];
}

- (void)stopAnnouncing {
    [mdnsService stop];
}
@end
