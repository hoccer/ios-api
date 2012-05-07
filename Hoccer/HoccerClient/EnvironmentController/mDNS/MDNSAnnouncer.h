//
//  MDNSAnnouncer.h
//  Hoccer
//
//  Created by Philip Brechler on 30.04.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDNSAnnouncer : NSObject <NSNetServiceDelegate> {
    NSNetService *mdnsService;
}

+ (MDNSAnnouncer *)sharedAnnouncer;

- (void)startAnnouncing;
- (void)stopAnnouncing;
@end
