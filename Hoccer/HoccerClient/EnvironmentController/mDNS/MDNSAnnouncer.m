//
//  MDNSAnnouncer.m
//  Hoccer
//
//  Created by Philip Brechler on 30.04.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import "MDNSAnnouncer.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#import <arpa/inet.h>
#include <CFNetwork/CFSocketStream.h>

static MDNSAnnouncer *mdnsAnnouncerInstance;


@implementation MDNSAnnouncer 
@synthesize mdnsService,connectionBag,ipv4socket;

+ (MDNSAnnouncer *)sharedAnnouncer {
    if (mdnsAnnouncerInstance == nil) {
        mdnsAnnouncerInstance = [[MDNSAnnouncer alloc] init];
    }
    return mdnsAnnouncerInstance;
}

- (id)init {
    self = [super init];
    isAnnouncing = NO;
    return self;
}

-(void)netServiceDidPublish:(NSNetService *)sender {
    NSLog(@"We did it");
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    
    NSLog(@"Oh noes!");
}

- (void) setupServer:(NSError **)error {
	uint16_t chosenPort = 0;
	struct sockaddr_in serverAddress;
	socklen_t nameLen = 0;
	nameLen = sizeof(serverAddress);
	
	if (self.mdnsService && ipv4socket) {
		// Calling [self run] more than once should be a NOP.
		return;
	} else {
        
		if (!ipv4socket) {
			CFSocketContext socketCtxt = {0, self, NULL, NULL, NULL};
			self.ipv4socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, NULL, &socketCtxt);
            
			if (!ipv4socket) {
				if (error) * error = [[NSError alloc] initWithDomain:@"HoccerErrorDomain" code:kCryptoServerNoSocketsAvailable userInfo:nil];
				[self stopAnnouncing];
				return;
			}
			
			int yes = 1;
			setsockopt(CFSocketGetNative(ipv4socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
			
			// set up the IPv4 endpoint; use port 0, so the kernel will choose an arbitrary port for us, which will be advertised using Bonjour
			memset(&serverAddress, 0, sizeof(serverAddress));
			serverAddress.sin_len = nameLen;
			serverAddress.sin_family = AF_INET;
			serverAddress.sin_port = 0;
			serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
			NSData * address4 = [NSData dataWithBytes:&serverAddress length:nameLen];
			
			if (kCFSocketSuccess != CFSocketSetAddress(ipv4socket, (CFDataRef)address4)) {
				if (error) *error = [[NSError alloc] initWithDomain:@"HoccerErrorDomain" code:kCryptoServerCouldNotBindToIPv4Address userInfo:nil];
				if (ipv4socket) CFRelease(ipv4socket);
				ipv4socket = NULL;
				return;
			}
			
			// now that the binding was successful, we get the port number 
			// -- we will need it for the NSNetService
			NSData * addr = [(NSData *)CFSocketCopyAddress(ipv4socket) autorelease];
			memcpy(&serverAddress, [addr bytes], [addr length]);
			chosenPort = ntohs(serverAddress.sin_port);
			
			// set up the run loop sources for the sockets
			CFRunLoopRef cfrl = CFRunLoopGetCurrent();
			CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv4socket, 0);
			CFRunLoopAddSource(cfrl, source, kCFRunLoopCommonModes);
			CFRelease(source);
		}
        
		if (!self.mdnsService && ipv4socket) {
			self.mdnsService = [[NSNetService alloc] initWithDomain:@"local" type:@"_hoccer._tcp" name:[[UIDevice currentDevice] name] port:chosenPort];
            NSDictionary *clientId = [NSDictionary dictionaryWithObjectsAndKeys:[[NSUserDefaults standardUserDefaults] stringForKey:@"mdnsId"],@"id", nil];
            NSData *clientData = [NSNetService dataFromTXTRecordDictionary:clientId];
            if (![self.mdnsService setTXTRecordData:clientData]) {
                NSLog(@"FAIL");
            }
			[self.mdnsService setDelegate:self];
		}
        
		if (!self.mdnsService && !ipv4socket) {
			if (error) *error = [[NSError alloc] initWithDomain:@"HoccerErrorDomain" code:kCryptoServerCouldNotBindOrEstablishNetService userInfo:nil];
			[self stopAnnouncing];
			return;
		}
	}
}


- (void)startAnnouncing {
    if (!isAnnouncing){
        [self setupServer:nil];
        [self.mdnsService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [self.mdnsService publish];
        isAnnouncing = YES;
    }
}

- (void)stopAnnouncing {
    if (self.mdnsService) {
		[self.mdnsService stop];
		[self.mdnsService removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		self.mdnsService = nil;
        isAnnouncing = NO;
	}
	if (self.ipv4socket) {
		CFSocketInvalidate(self.ipv4socket);
		CFRelease(self.ipv4socket);
		self.ipv4socket = NULL;
	}}
@end
