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

#import <YAJLiOS/YAJL.h>
#import "NSString+URLHelper.h"
#import "NSDictionary+CSURLParams.h"
#import "NSString+StringWithData.h"
#import "NSData_Base64Extensions.h"
#import "HCLinccer.h"
#import "HCEnvironmentManager.h"
#import "HCEnvironment.h"
#import "HttpClient.h"
#import "HttpConnection.h"

#import "HCAuthenticatedHttpClient.h"

#import "RSA.h"
#import "PublicKeyManager.h"

#define LINCCER_URI @"https://linccer.hoccer.com/v3"
#define LINCCER_SANDBOX_URI @"https://linccer-experimental.hoccer.com/v3"
//#define LINCCER_SANDBOX_URI @"https://linccer-sandbox.hoccer.com/v3"
#define HOCCER_CLIENT_ID_KEY @"hoccerClientUri" 

@interface HCLinccer ()
@property (retain) NSTimer *updateTimer;
@property (copy) NSString *linccingId;
@property (copy) NSString *peekId;
@property (copy) NSString *groupId;

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
@synthesize peekId;
@synthesize userInfo;
@synthesize groupId;

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret {
	return [self initWithApiKey:key secret:secret sandboxed:NO];
}

- (id) initWithApiKey:(NSString *)key secret:(NSString *)secret sandboxed: (BOOL)sandbox {
	self = [super init];
	if (self != nil) {
       userInfo = [[NSDictionary dictionaryWithObject:@"<unknown>" forKey:@"client_name"] retain];
        
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
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(reactivate) userInfo:nil repeats:NO];
        
        //[[RSA sharedInstance] testEncryption];
        
        keyManager = [[PublicKeyManager alloc] init];
        
        clientIDCache = [[NSMutableDictionary alloc]init];

	}
	
	return self;	
}

- (void)send: (NSDictionary *)data withMode: (NSString *)mode {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	
    NSData *dataToSend = [[data yajl_JSONString] dataUsingEncoding:NSUTF8StringEncoding]; 
    
	NSString *actionString = [@"/action" stringByAppendingPathComponent:mode];
	self.linccingId = [httpClient putURI:[uri stringByAppendingPathComponent: actionString] 
				payload: dataToSend
				success:@selector(httpConnection:didSendData:)];
}

- (void)send: (NSDictionary *)data withMode: (NSString *)mode encrypted:(BOOL)encrypted {
    if (!encrypted) {
        [self send:data withMode:mode];
    }
    else {
        
    }
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


- (void)checkGroupForPublicKeys:(NSDictionary *)aDictionary{
    
    NSArray *theGroup = [aDictionary objectForKey:@"group"];
    NSMutableArray *others = [NSMutableArray arrayWithCapacity:[theGroup count]];
    for (NSDictionary *dict in theGroup) {
        if (![[dict objectForKey:@"id"] isEqual:[self uuid]]) {
            [others addObject:dict];            
        }
    }
    
    for (NSDictionary *aClient in others) {
        if ([aClient objectForKey:@"pubkey_id"] !=nil){
            if ([keyManager getKeyForClient:aClient] == nil){
                [self fetchPublicKeyForHash:[aClient objectForKey:@"pubkey_id"] client:aClient clientChanged:NO];
            }
            else {
                if ([keyManager checkForKeyChange:aClient withHash:[aClient objectForKey:@"pubkey_id"]]){
                    [self fetchPublicKeyForHash:[aClient objectForKey:@"pubkey_id"] client:aClient clientChanged:YES];
                }
            }
        }
    }
    
}

- (void)fetchPublicKeyForHash:(NSString *)theHash client:(NSDictionary *)client clientChanged:(BOOL)changed{
    
    if (!isRegistered) {
        [self didFailWithError:nil];
    }
    
    if (!changed){
        NSString *fetchString = [theHash stringByAppendingPathComponent:@"publickey"];
        [httpClient getURI:[uri stringByAppendingPathComponent:fetchString] success:@selector(httpConnection:didReceivePublicKey:)];
        [clientIDCache setObject:client forKey:theHash];
    }
    else {
        NSString *fetchString = [theHash stringByAppendingPathComponent:@"publickey"];
        [httpClient getURI:[uri stringByAppendingPathComponent:fetchString] success:@selector(httpConnection:didReceiveChangedPublicKey:)];
        [clientIDCache setObject:client forKey:theHash];
    }

}

- (void)storePublicKey:(NSString *)theKey forClient:(NSDictionary *)client clientChanged:(BOOL)changed{
    if (changed){
        [keyManager deleteKeyForClient:[client objectForKey:@"id"]];
    }
    if (theKey != nil){
        if (![keyManager storeKey:theKey forClient:client]){
            NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
            [errorInfo setObject:[NSString stringWithFormat:NSLocalizedString(@"Could not save public key for client %@", nil),[client objectForKey:@"name"]] forKey:NSLocalizedDescriptionKey];
            [errorInfo setObject:NSLocalizedString(@"Disable encryption and enable it again", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
            
            NSError *error = [NSError errorWithDomain:@"PubKeyError" code:700 userInfo:errorInfo];
            
            
            [self didFailWithError:error];
        }
        else {
            if (changed){
                if ([delegate respondsToSelector:@selector(linccer:keyHasChangedForClientName:)]){
                    [delegate linccer:self keyHasChangedForClientName:[client objectForKey:@"name"]];
                }
            }
        }
    }
    
}


- (void)reactivate {
    isRegistered = NO;
    [environmentController activateLocation];

	[self updateEnvironment];
    self.groupId = nil;
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
	[environmentController deactivateLocation];
	[httpClient deleteURI:[uri stringByAppendingPathComponent:@"/environment"]
				  success:@selector(httpClientDidDelete:)];
    
    
}


#pragma mark -
#pragma mark Error Handling 

- (void)httpConnection:(HttpConnection *)connection didFailWithError: (NSError *)error {
	if ([linccingId isEqual: connection.uri]) {
        self.linccingId = nil;
    }
    
    if ([self.peekId isEqual:connection.uri]) {
        [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(peek) userInfo:nil repeats:NO];
    }
    
    if ([connection isLongpool] && ([error code] == 504)) {
		NSURL *url = [NSURL URLWithString:connection.uri];
		
		[httpClient getURI:[[url path] stringByAppendingQuery:@"waiting=true"]
				   success:@selector(httpConnection:didReceiveData:)];	
		
		return;
	} 
	
	if ([error code] == 409) {
		NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
		[errorInfo setObject:NSLocalizedString(@"There was a collision of actions.", nil) forKey:NSLocalizedDescriptionKey];
		[errorInfo setObject:NSLocalizedString(@"Try again", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
		
		error = [NSError errorWithDomain:HoccerError code:409 userInfo:errorInfo];
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
	
    @try {
        if ([delegate respondsToSelector:@selector(linccer:didReceiveData:)]) {        
            [delegate linccer: self didReceiveData: [data yajl_JSON]];
        }
    }
    @catch (NSException * e) { NSLog(@"%@", e); }

}

- (void)httpClientDidDelete: (NSData *)receivedData {
	if ([delegate respondsToSelector:@selector(linccerDidUnregister:)]) {
		[delegate linccerDidUnregister: self];
	}
}

- (void)httpConnection: (HttpConnection *)connection didUpdateGroup: (NSData *)groupData {
    
    @try {
	
    
    NSDictionary *dictionary = [groupData yajl_JSON];

    self.groupId = [dictionary objectForKey:@"group_id"];
    
    if ([delegate respondsToSelector:@selector(linccer:didUpdateGroup:)]) {
        [delegate linccer:self didUpdateGroup:[dictionary objectForKey:@"group"]];
    }
    
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"encryption"] == YES){
            [self checkGroupForPublicKeys:dictionary];
        }
     
    [self peek];
        
    
    }
    @catch (NSException * e) { NSLog(@"%@", e); }

}

- (void)httpConnection: (HttpConnection *)connection didReceivePublicKey: (NSData *)pubkey{
   

    //NSString *theKey = [[[NSString stringWithData: pubkey usingEncoding:NSUTF8StringEncoding]componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
    
    @try {
        NSDictionary *theResponse = [pubkey yajl_JSON];
        
        NSString *theKey = [theResponse objectForKey:@"pubkey"];
        
        
        NSArray *uriArray = [connection.uri componentsSeparatedByString:@"/"];
        NSString *identifier = [uriArray objectAtIndex:6];
        [self storePublicKey:theKey forClient:[clientIDCache objectForKey:identifier] clientChanged:NO];
    }
    @catch (NSException * e) { NSLog(@"%@", e); }

    
}

- (void)httpConnection: (HttpConnection *)connection didReceiveChangedPublicKey: (NSData *)pubkey{
    
    
    @try {
        NSDictionary *theResponse = [pubkey yajl_JSON];
        
        NSString *theKey = [theResponse objectForKey:@"pubkey"];
        
        
        NSArray *uriArray = [connection.uri componentsSeparatedByString:@"/"];
        NSString *identifier = [uriArray objectAtIndex:6];
        [self storePublicKey:theKey forClient:[clientIDCache objectForKey:identifier] clientChanged:NO];
    }
    @catch (NSException * e) { NSLog(@"%@", e); }
}
#pragma mark -
#pragma mark Private Methods

- (NSDictionary *)userInfoForNoReceiver {

	NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
	[info setObject:NSLocalizedString(@"No receiver was found.", nil) forKey:NSLocalizedDescriptionKey];
	[info setObject:NSLocalizedString(@"Try again", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
		
	return [info autorelease];
}

- (NSDictionary *)userInfoForNoSender {
	NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
	[info setObject:NSLocalizedString(@"No sender was found.", nil) forKey:NSLocalizedDescriptionKey];
	[info setObject:NSLocalizedString(@"Try again", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
	
	return [info autorelease];	
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
	[environment setObject:[NSNumber numberWithDouble:self.latency * 1000] forKey:@"latency"];
    [environment addEntriesFromDictionary:self.userInfo];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"autoKey"]){
        NSData *pubKey = [[RSA sharedInstance] getPublicKeyBits];
        NSString *pubKeyAsString = [pubKey asBase64EncodedString];
        if (pubKeyAsString){
            [environment setObject:pubKeyAsString forKey:@"pubkey"];
        }
        }
     
    NSString *enviromentAsString = [environment yajl_JSONString];
         
	[httpClient putURI:[uri stringByAppendingPathComponent:@"/environment"]
			   payload:[enviromentAsString dataUsingEncoding:NSUTF8StringEncoding] 
			   success:@selector(httpConnection:didUpdateEnvironment:)];
    
    [environment release];
}

- (void)cancelAllRequest {
	[httpClient cancelAllRequest];
    self.linccingId = nil;
    
    [self peek];
}


- (void)peek {
    NSString *peekUri = [uri stringByAppendingPathComponent:@"/peek"];
    if (groupId) {
        NSDictionary *params = [NSDictionary dictionaryWithObject:groupId forKey:@"group_id"];
        peekUri = [peekUri stringByAppendingQuery:[params URLParams]];
    }

    self.peekId = [httpClient getURI:peekUri success:@selector(httpConnection:didUpdateGroup:)];
}


#pragma mark -
#pragma mark Getter

- (NSString *)uuid {
    if (uuid != nil) {
        return uuid;
    }

    BOOL shouldCreateNewUUID = [[NSUserDefaults standardUserDefaults] boolForKey:@"renewUUID"];
    uuid                     = [[[NSUserDefaults standardUserDefaults] stringForKey:HOCCER_CLIENT_ID_KEY] copy];
    
	if (shouldCreateNewUUID || !uuid) {
		uuid = [[NSString stringWithUUID] copy];
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

-(void)setUserInfo:(NSDictionary *)newUserInfo {
    if (newUserInfo != userInfo) {
        [userInfo release];
        userInfo = [newUserInfo retain];
        
        [self reactivate];
    }
}

- (void)dealloc {
	[httpClient cancelAllRequest];
	httpClient.target = nil;
	[httpClient release];
	
	[environmentController release];
	[uri release];
	[updateTimer release];
    
    [peekId release];
    [linccingId release];
    [groupId release];
    
    
    [uuid release];
    [userInfo release];
    [super dealloc];
}

@end