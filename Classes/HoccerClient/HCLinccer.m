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
//  Hoccer.m
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <YAJLIOS/YAJLIOS.h>
#import "NSString+URLHelper.h"
#import "NSDictionary+CSURLParams.h"
#import "HCLinccer.h"
#import "HCEnvironmentManager.h"
#import "HCEnvironment.h"
#import "HttpClient.h"
#import "HttpConnection.h"

#import "HCAuthenticatedHttpClient.h"

#define LINCCER_URI @"https://linccer.hoccer.com/v3"
// #define LINCCER_SANDBOX_URI @"https://linccer-beta.hoccer.com/v3"
#define LINCCER_SANDBOX_URI @"http://192.168.2.126:9292/v3"
#define HOCCER_CLIENT_ID_KEY @"hoccerClientUri" 

@interface HCLinccer ()
@property (retain) NSTimer *updateTimer;
@property (copy) NSString *linccingId;

- (void)updateEnvironment;
- (void)didFailWithError: (NSError *)error;
- (void)peek;

- (NSDictionary *)userInfoForNoReceiver;
- (NSDictionary *)userInfoForNoSender;
@end

@implementation HCLinccer
@synthesize updateTimer;
@synthesize delegate;
@synthesize environmentController;
@synthesize isRegistered;
@synthesize latency;
@synthesize environmentUpdateInterval;
@synthesize linccingId;

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret {
	return [self initWithApiKey:key secret:secret sandboxed:NO];
}

- (id) initWithApiKey:(NSString *)key secret:(NSString *)secret sandboxed: (BOOL)sandbox {
	self = [super init];
	if (self != nil) {
		environmentController = [[HCEnvironmentManager alloc] init];
		environmentController.delegate = self;
		
		if (sandbox) {
			httpClient = [[HCAuthenticatedHttpClient alloc] initWithURLString:LINCCER_SANDBOX_URI];
		} else {
			httpClient = [[HCAuthenticatedHttpClient alloc] initWithURLString:LINCCER_URI];
		}
		
		httpClient.apiKey = key;
		httpClient.secret = secret;
		httpClient.target = self;
		
		uri = [[@"/clients" stringByAppendingPathComponent:[self uuid]] retain];
		environmentUpdateInterval = 20;	
		[self reactivate];
	}
	
	return self;	
}

- (void)send: (NSDictionary *)data withMode: (NSString *)mode {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	
	NSString *actionString = [@"/action" stringByAppendingPathComponent:mode];
	[httpClient putURI:[uri stringByAppendingPathComponent: actionString] 
				payload:[[data yajl_JSONString] dataUsingEncoding:NSUTF8StringEncoding] 
				success:@selector(httpConnection:didSendData:)];
    
}

- (void)receiveWithMode: (NSString *)mode {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	
	NSString *actionString = [@"/action" stringByAppendingPathComponent:mode];
	
	self.linccingId = [httpClient getURI:[uri stringByAppendingPathComponent: actionString]
			   success:@selector(httpConnection:didReceiveData:)];	
    
}

- (void)pollWithMode: (NSString *)mode {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	
	NSString *actionString = [@"/action" stringByAppendingPathComponent:mode];
	[httpClient getURI:[uri stringByAppendingPathComponent: [actionString stringByAppendingQuery:@"waiting=true"]]
			   success:@selector(httpConnection:didReceiveData:)];	
	
}

- (void)reactivate {
	[self updateEnvironment];
}

- (BOOL)isLinccing {
	return self.linccingId != nil;
}


- (void)disconnect {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	[self.updateTimer invalidate];
	self.updateTimer = nil;
	
	[httpClient deleteURI:[uri stringByAppendingPathComponent:@"/environment"]
				  success:@selector(httpClientDidDelete:)];
}


#pragma mark -
#pragma mark Error Handling 

- (void)httpConnection:(HttpConnection *)connection didFailWithError: (NSError *)error {	
	if (linccingId == connection.uri) {
        self.linccingId = nil;
    }
    
    if ([connection isLongpool] && ([error code] == 504)) {
		NSURL *url = [NSURL URLWithString:connection.uri];
		
		[httpClient getURI:[[url path] stringByAppendingQuery:@"waiting=true"]
				   success:@selector(httpConnection:didReceiveData:)];	
		
		return;
	} 
	
	if ([error code] == 409) {
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:NSLocalizedString(@"There was a collision of actions.", nil) forKey:NSLocalizedDescriptionKey];
		[userInfo setObject:NSLocalizedString(@"Try again", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
		
		error = [NSError errorWithDomain:HoccerError code:409 userInfo:userInfo];
	}
											 
	[self didFailWithError:error];
}

- (void)didFailWithError: (NSError *)error {
	if ([delegate respondsToSelector:@selector(linccer:didFailWithError:)]) {
		[delegate linccer: self didFailWithError:error];
	}
}

#pragma mark -
#pragma mark LocationController Delegate Methods

- (void)environmentManagerDidUpdateEnvironment: (HCEnvironmentManager *)controller {
	[self updateEnvironment];
}

#pragma mark -
#pragma mark HttpClient Response Methods 

- (void)httpConnection: (HttpConnection *)aConnection didUpdateEnvironment: (NSData *)receivedData {		
	self.latency = aConnection.roundTripTime;
	
    
    if (!isRegistered) {
        if ([delegate respondsToSelector:@selector(linccerDidRegister:)]) {
            [delegate linccerDidRegister:self];
        }
        
        [self peek];
    }
	isRegistered = YES;
	
	@try {
		if ([delegate respondsToSelector:@selector(linccer:didUpdateEnvironment:)]) {
			[delegate linccer:self didUpdateEnvironment:[receivedData yajl_JSON]];
		}
	}
	@catch (NSException * e) { NSLog(@"%@", e); }
}

- (void)httpConnection: (HttpConnection *)connection didSendData: (NSData *)data {
    self.linccingId = nil;

	if ([connection.response statusCode] == 204 ) {
		NSError *error = [NSError errorWithDomain:HoccerError code:HoccerNoReceiverError userInfo:[self userInfoForNoReceiver]];
		[self didFailWithError:error];
		return;
	}


	if ([delegate respondsToSelector:@selector(linccer:didSendData:)]) {
		[delegate linccer: self didSendData: [data yajl_JSON]];
	}
}

- (void)httpConnection: (HttpConnection *)connection didReceiveData: (NSData *)data {
    self.linccingId = nil;
    
    if ([connection.response statusCode] == 204 ) {
		NSError *error = [NSError errorWithDomain:HoccerError code:HoccerNoSenderError userInfo:[self userInfoForNoSender]];
		[self didFailWithError:error];
		return;
	}
	
    if ([delegate respondsToSelector:@selector(linccer:didReceiveData:)]) {
		[delegate linccer: self didReceiveData: [data yajl_JSON]];
	}
}

- (void)httpClientDidDelete: (NSData *)receivedData {
	if ([delegate respondsToSelector:@selector(linccerDidUnregister:)]) {
		[delegate linccerDidUnregister: self];
	}
}

#pragma mark -
#pragma mark Private Methods

- (NSDictionary *)userInfoForNoReceiver {

	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:NSLocalizedString(@"No receiver was found.", nil) forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:NSLocalizedString(@"Try again", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
		
	return [userInfo autorelease];
}

- (NSDictionary *)userInfoForNoSender {
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
	[userInfo setObject:NSLocalizedString(@"No sender was found.", nil) forKey:NSLocalizedDescriptionKey];
	[userInfo setObject:NSLocalizedString(@"Try again", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
	
	return [userInfo autorelease];	
}

- (void)updateEnvironment {	
	[updateTimer invalidate];
	self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:self.environmentUpdateInterval
														target:self 
													  selector:@selector(updateEnvironment) 
													  userInfo:nil 
													   repeats:NO];
	
	if (uri == nil || ![self.environmentController hasEnvironment]) {
		return;
	}
	
	NSMutableDictionary *environment = [[environmentController.environment dict] mutableCopy];
	[environment setObject:[NSNumber numberWithDouble:self.latency*1000] forKey:@"latency"];
    [environment setObject:[UIDevice currentDevice].name forKey:@"client_name"];
    
	[httpClient putURI:[uri stringByAppendingPathComponent:@"/environment"]
			   payload:[[environment yajl_JSONString] dataUsingEncoding:NSUTF8StringEncoding] 
			   success:@selector(httpConnection:didUpdateEnvironment:)];
}

- (void)cancelAllRequest {
	[httpClient cancelAllRequest];
}


- (void)peek {
    NSString *peekUri = [uri stringByAppendingPathComponent:@"/peek"];
    if (groupId) {
        NSDictionary *params = [NSDictionary dictionaryWithObject:groupId forKey:@"group_id"];
        peekUri = [peekUri stringByAppendingQuery:[params URLParams]];
    }

    NSLog(@"peekURL %@", peekUri);
    [httpClient getURI:peekUri success:@selector(httpConnection:didUpdateGroup:)];
}

- (void)httpConnection: (HttpConnection *)connection didUpdateGroup: (NSDictionary *)groupDictionary {
    NSDictionary *dictionary = [groupDictionary yajl_JSON];
    groupId = [dictionary objectForKey:@"group_id"];
    
    if ([delegate respondsToSelector:@selector(linccer:didUpdateGroup:)]) {
        [delegate linccer:self didUpdateGroup:[dictionary objectForKey:@"group"]];
    }
    
    [self peek];
}


#pragma mark -
#pragma mark Getter

- (NSString *)uuid {
	NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:HOCCER_CLIENT_ID_KEY];
	if (!uuid) {
		uuid = [NSString stringWithUUID];
		[[NSUserDefaults standardUserDefaults] setObject:uuid forKey:HOCCER_CLIENT_ID_KEY];
	}

	return uuid;
}

#pragma mark -
#pragma mark Setter

- (void) setEnvironmentUpdateInterval:(NSTimeInterval)newInterval {
	if (environmentUpdateInterval != newInterval) {
		environmentUpdateInterval = newInterval;
		[self.updateTimer invalidate];
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:self.environmentUpdateInterval
															target:self 
														  selector:@selector(updateEnvironment) 
														  userInfo:nil 
														   repeats:NO];
	
	}
}

- (void)dealloc {
	[httpClient cancelAllRequest];
	httpClient.target = nil;
	[httpClient release];
	
	[environmentController release];
	[uri release];
	[updateTimer release];
    [super dealloc];
}

@end