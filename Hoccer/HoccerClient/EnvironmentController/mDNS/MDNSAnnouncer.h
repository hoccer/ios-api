//
//  MDNSAnnouncer.h
//  Hoccer
//
//  Created by Philip Brechler on 30.04.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kCryptoServerCouldNotBindToIPv4Address = 1,
    kCryptoServerCouldNotBindToIPv6Address = 2,
    kCryptoServerNoSocketsAvailable = 3,
	kCryptoServerCouldNotBindOrEstablishNetService = 4
} CryptoServerErrorCode;


@interface MDNSAnnouncer : NSObject <NSNetServiceDelegate> {
    NSMutableSet * connectionBag;
    NSNetService *mdnsService;
    CFSocketRef ipv4socket;
    BOOL isAnnouncing;
}

@property (nonatomic, retain) NSNetService *mdnsService;
@property (nonatomic, retain) NSMutableSet *connectionBag;
@property (assign) CFSocketRef ipv4socket;

+ (MDNSAnnouncer *)sharedAnnouncer;

- (void) setupServer:(NSError **)error;
- (void)startAnnouncing;
- (void)stopAnnouncing;
@end
