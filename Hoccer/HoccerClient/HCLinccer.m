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

#define LINCCER_URI @"https://linccer-production.hoccer.com/v3"
#define LINCCER_SANDBOX_URI @"https://linccer-experimental.hoccer.com/v3"

// #define LINCCER_URI @"https://linccer-production.hoccer.com/v3"
// #define LINCCER_SANDBOX_URI @"https://linccer-development.hoccer.com/v3"
//#define LINCCER_SANDBOX_URI @"https://linccer-sandbox.hoccer.com/v3"

#define HOCCER_CLIENT_ID_KEY @"hoccerClientUri" 

@interface HCLinccer ()
@property (retain) NSTimer *updateTimer;
@property (copy) NSString *linccingId;
@property (copy) NSString *peekId;
@property (copy) NSString *groupId;
@property (copy) NSString *envUpdateId;

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
@synthesize lastEnvironmentupdate;
@synthesize linccingId;
@synthesize peekId;
@synthesize userInfo;
@synthesize groupId;
@synthesize envUpdateId;

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
		environmentUpdateInterval = 30;
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(reactivate) userInfo:nil repeats:NO];
        
        //[[RSA sharedInstance] testEncryption];
        
        keyManager = [[PublicKeyManager alloc] init];
        
        clientIDCache = [[NSMutableDictionary alloc]init];

	}
	
	return self;	
}

- (void)send:(NSDictionary *)data withMode:(NSString *)mode {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
    @try {
        NSData *dataToSend = [[data yajl_JSONString] dataUsingEncoding:NSUTF8StringEncoding];
        
        NSLog(@"send %@", [data yajl_JSONString]);
        
        NSString *actionString = [@"/action" stringByAppendingPathComponent:mode];
        self.linccingId = [httpClient putURI:[uri stringByAppendingPathComponent: actionString] 
                    payload: dataToSend
                    success:@selector(httpConnection:didSendData:)];
    }
    @catch (NSException *e) {
        if (USES_DEBUG_MESSAGES) { NSLog(@"HCLinccer send:%@ withMode:%@ execption : %@", data, mode, e); }
        else { NSLog(@"%@", e); }
    }
}

- (void)send:(NSDictionary *)data withMode:(NSString *)mode encrypted:(BOOL)encrypted {
    if (!encrypted) {
        [self send:data withMode:mode];
    }
    else {
        
    }
}

- (void)receiveWithMode:(NSString *)mode {
	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	
	NSString *actionString = [@"/action" stringByAppendingPathComponent:mode];
	
	self.linccingId = [httpClient getURI:[uri stringByAppendingPathComponent: actionString]
			   success:@selector(httpConnection:didReceiveData:)];
}

- (void)pollWithMode:(NSString *)mode
{
	if (!isRegistered) {
		[self didFailWithError:nil];
        //warum hier nicht return - wenn er nicht registered ist braucht der nachfolgende request nicht rausgehen - oder?
	}
	
	NSString *actionString = [@"/action" stringByAppendingPathComponent:mode];
	[httpClient getURI:[uri stringByAppendingPathComponent: [actionString stringByAppendingQuery:@"waiting=true"]]
			   success:@selector(httpConnection:didReceiveData:)];
}


- (void)checkGroupForPublicKeys:(NSDictionary *)aDictionary
{    
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

- (void)fetchPublicKeyForHash:(NSString *)theHash client:(NSDictionary *)client clientChanged:(BOOL)changed
{
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

- (void)storePublicKey:(NSString *)theKey forClient:(NSDictionary *)client clientChanged:(BOOL)changed
{
    if (changed){
        [keyManager deleteKeyForClient:[client objectForKey:@"id"]];
    }
    if (theKey != nil){
        if (![keyManager storeKey:theKey forClient:client]){
            NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
            [errorInfo setObject:[NSString stringWithFormat:NSLocalizedString(@"Message_PublicKeyMaybeInvalid", nil),[client objectForKey:@"name"]] forKey:NSLocalizedDescriptionKey];
            [errorInfo setObject:NSLocalizedString(@"RecoverySuggestion_PublicKeyMaybeInvalid", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
            
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
    if (USES_DEBUG_MESSAGES) { NSLog(@"HCLinccer: reactivate:"); }
    isRegistered = NO;
    [environmentController activateLocation];

	[self updateEnvironment];
    self.groupId = nil;
    [self peek];
}

- (BOOL)isLinccing {
	return self.linccingId != nil;
}


- (void)disconnect {
    if (USES_DEBUG_MESSAGES) { NSLog(@"HCLinccer: disconnect:"); }

	if (!isRegistered) {
		[self didFailWithError:nil];
	}
	[self.updateTimer invalidate];
	self.updateTimer = nil;
	[environmentController deactivateLocation];
    if (self.peekId != nil) {
        [httpClient cancelRequest:(self.peekId)];
        self.peekId = nil;
    }
	[httpClient deleteURI:[uri stringByAppendingPathComponent:@"/environment"]
				  success:@selector(httpClientDidDelete:)];
    self.envUpdateId = nil;
    
    
}


#pragma mark -
#pragma mark Error Handling 

- (void)httpConnection:(HttpConnection *)connection didFailWithError:(NSError *)error {
	if ([linccingId isEqual: connection.uri]) {
        self.linccingId = nil;
    }

    if (USES_DEBUG_MESSAGES) { NSLog(@"  HCLinccer HttpConnection didFailWithError - error :   %@", error); }
    if (USES_DEBUG_MESSAGES) { NSLog(@"  HCLinccer HttpConnection didFailWithError statuscode:  %d", connection.response.statusCode); }

    if ([self.peekId isEqual:connection.uri]) {
        self.peekId = nil;
        [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(peek) userInfo:nil repeats:NO];
    }
    if ([self.envUpdateId isEqual:connection.uri]) {
        self.envUpdateId = nil;
    }
    
    if ([connection isLongPoll] && ([error code] == 504)) {
		NSURL *url = [NSURL URLWithString:connection.uri];
		
		[httpClient getURI:[[url path] stringByAppendingQuery:@"waiting=true"]
				   success:@selector(httpConnection:didReceiveData:)];	
		
		return;
	} 
	
	if ([error code] == 409) {
		NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
		[errorInfo setObject:NSLocalizedString(@"Message_TooManyFilesFlyingAround", nil) forKey:NSLocalizedDescriptionKey];
		[errorInfo setObject:NSLocalizedString(@"RecoverySuggestion_TooManyFilesFlyingAround", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
		
		error = [NSError errorWithDomain:HoccerError code:409 userInfo:errorInfo];
	}
											 
	[self didFailWithError:error];
}

- (void)didFailWithError:(NSError *)error
{
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

- (void)httpConnection:(HttpConnection *)connection didUpdateEnvironment:(NSData *)receivedData {
	self.latency = connection.roundTripTime;
	
    if (USES_DEBUG_MESSAGES) { NSLog(@"  HCLinccer HttpConnection didUpdateEnvironment request   %@", connection.request); }
    if (USES_DEBUG_MESSAGES) { NSLog(@"  HCLinccer HttpConnection didUpdateEnvironment statuscode:  %d", connection.response.statusCode); }
    if (USES_DEBUG_MESSAGES) { NSLog(@"  HCLinccer HttpConnection didUpdateEnvironment - error :   %@", [NSString stringWithData:receivedData usingEncoding:NSUTF8StringEncoding]); }

    if (!isRegistered) {
        if ([delegate respondsToSelector:@selector(linccerDidRegister:)]) {
            [delegate linccerDidRegister:self];
        }
        
        [self peek];
    }
	isRegistered = YES;
    
    self.envUpdateId = nil;
	
	@try {
		if ([delegate respondsToSelector:@selector(linccer:didUpdateEnvironment:)]) {
            if (USES_DEBUG_MESSAGES) { NSLog(@"HCLinccer didUpdateEnvironment - receivedData : %@", receivedData); }
			[delegate linccer:self didUpdateEnvironment:[receivedData yajl_JSON]];
		}
	}
	@catch (NSException * e) {
        if (USES_DEBUG_MESSAGES) { NSLog(@"HCLinccer didUpdateEnvironment - error : %@", e); }
        else { NSLog(@"%@", e); }
    }
}

- (void)httpConnection:(HttpConnection *)connection didSendData:(NSData *)data
{
    self.linccingId = nil;
    if (USES_DEBUG_MESSAGES) { NSLog(@"  HCLinccer HttpConnection didSendData statuscode:  %d", connection.response.statusCode); }

	if ([connection.response statusCode] == 204 ) {
		NSError *error = [NSError errorWithDomain:HoccerError code:HoccerNoReceiverError userInfo:[self userInfoForNoReceiver]];
		[self didFailWithError:error];
		return;
	}
    @try {
        if ([delegate respondsToSelector:@selector(linccer:didSendData:)]) {
            if (USES_DEBUG_MESSAGES) {
                NSLog(@"HCLinccer didSendData - data : %@",
                       [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
            }
            [delegate linccer: self didSendData: [data yajl_JSON]];
        }
    }
    @catch (NSException * e) {
        if (USES_DEBUG_MESSAGES, YES) { NSLog(@"HCLinccer didSendData - error : %@", e); }
        else { NSLog(@"%@", e); }
    }
}

- (void)httpConnection:(HttpConnection *)connection didReceiveData:(NSData *)data
{
    self.linccingId = nil;
    
    if (USES_DEBUG_MESSAGES) { NSLog(@"  HCLinccer HttpConnection didReceiveData   %@", connection.request); }
    if (USES_DEBUG_MESSAGES) { NSLog(@"  HCLinccer HttpConnection didReceiveData statuscode:  %d", connection.response.statusCode); }    
    if (USES_DEBUG_MESSAGES) { NSLog(@"  HCLinccer HttpConnection didReceiveData - error :   %@", [NSString stringWithData:data usingEncoding:NSUTF8StringEncoding]); }
    
    if ([connection.response statusCode] == 204 ) {
		NSError *error = [NSError errorWithDomain:HoccerError code:HoccerNoSenderError userInfo:[self userInfoForNoSender]];
		[self didFailWithError:error];
		return;
	}
    
    if ([connection.response statusCode] == 504 ) {
		NSError *error = [NSError errorWithDomain:HoccerError code:504 userInfo:nil];
		[self didFailWithError:error];
		return;
	}
	
    @try {
        if ([delegate respondsToSelector:@selector(linccer:didReceiveData:)]) {
            if (USES_DEBUG_MESSAGES) { NSLog(@"HCLinccer didReceiveData - data : %@", data); }
            [delegate linccer: self didReceiveData: [data yajl_JSON]];
        }
    }
    @catch (NSException * e) {
        if (USES_DEBUG_MESSAGES, YES) { NSLog(@"HCLinccer didReceiveData : %@", e); }
        else { NSLog(@"%@", e); }
    }

}

- (void)httpClientDidDelete: (NSData *)receivedData {
    [self cancelAllRequestsIncludingPeek];
	if ([delegate respondsToSelector:@selector(linccerDidUnregister:)]) {
		[delegate linccerDidUnregister: self];
	}
}

- (void)httpConnection: (HttpConnection *)connection didUpdateGroup: (NSData *)groupData {
    
    @try {
        
        if (USES_DEBUG_MESSAGES) { NSLog(@"  HCLinccer HttpConnection didUpdateGroup   %@", connection.request); }
        self.peekId = nil;
    
        NSDictionary *dictionary = [groupData yajl_JSON];

        self.groupId = [dictionary objectForKey:@"group_id"];
        
        if ([delegate respondsToSelector:@selector(linccer:didUpdateGroup:)]) {
            if (USES_DEBUG_MESSAGES) { NSLog(@"HCLinccer didUpdateGroup - groupData : %@", groupData); }
            [delegate linccer:self didUpdateGroup:[dictionary objectForKey:@"group"]];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"encryption"] == YES){
            [self checkGroupForPublicKeys:dictionary];
        }
        
        [self peek];
    }
    @catch (NSException * e) {
        if (USES_DEBUG_MESSAGES) { NSLog(@"HCLinccer didUpdateGroup : %@", e); }
        else { NSLog(@"%@", e); }
    }

}

- (void)httpConnection: (HttpConnection *)connection didReceivePublicKey: (NSData *)pubkey
{

    //NSString *theKey = [[[NSString stringWithData: pubkey usingEncoding:NSUTF8StringEncoding]componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@""];
    
    @try {
        NSDictionary *theResponse = [pubkey yajl_JSON];
        
        NSString *theKey = [theResponse objectForKey:@"pubkey"];
        
        
        NSArray *uriArray = [connection.uri componentsSeparatedByString:@"/"];
        NSString *identifier = [uriArray objectAtIndex:6];
        [self storePublicKey:theKey forClient:[clientIDCache objectForKey:identifier] clientChanged:NO];
    }
    @catch (NSException * e) {
        if (USES_DEBUG_MESSAGES) { NSLog(@"HCLinccer didReceivePublicKey : %@", e); }
        else { NSLog(@"%@", e); }
    }
}

- (void)httpConnection: (HttpConnection *)connection didReceiveChangedPublicKey: (NSData *)pubkey
{
    @try {
        NSDictionary *theResponse = [pubkey yajl_JSON];
        
        NSString *theKey = [theResponse objectForKey:@"pubkey"];
        
        
        NSArray *uriArray = [connection.uri componentsSeparatedByString:@"/"];
        NSString *identifier = [uriArray objectAtIndex:6];
        [self storePublicKey:theKey forClient:[clientIDCache objectForKey:identifier] clientChanged:NO];
    }
    @catch (NSException * e) {
        if (USES_DEBUG_MESSAGES) { NSLog(@"HCLinccer didReceiveChangedPublicKey : %@", e); }
        else { NSLog(@"%@", e); }
    }
}

#pragma mark -
#pragma mark Private Methods

- (NSDictionary *)userInfoForNoReceiver {

	NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
	[info setObject:NSLocalizedString(@"Message_NoReceiver", nil) forKey:NSLocalizedDescriptionKey];
	[info setObject:NSLocalizedString(@"RecoverySuggestion_NoReceiver", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
		
	return [info autorelease];
}

- (NSDictionary *)userInfoForNoSender {
	NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
	[info setObject:NSLocalizedString(@"Message_NoSender", nil) forKey:NSLocalizedDescriptionKey];
	[info setObject:NSLocalizedString(@"RecoverySuggestion_NoSender", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
	
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
    
    if (self.envUpdateId != nil) {
        if (USES_DEBUG_MESSAGES) {NSLog(@"updateEnvironment call pending, not issuing new call");}
        return;
    }
        
    if (self.lastEnvironmentupdate != nil && [self.lastEnvironmentupdate timeIntervalSinceNow] > -2.0 ) {
        if (USES_DEBUG_MESSAGES) {NSLog(@"updateEnvironment call has been issued before less than 2 sec.");}
        return;
    }
    
	NSMutableDictionary *environment = [[environmentController.environment dict] mutableCopy];
	[environment setObject:[NSNumber numberWithDouble:self.latency * 1000] forKey:@"latency"];
    [environment addEntriesFromDictionary:self.userInfo];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"encryption"] &&
        [[NSUserDefaults standardUserDefaults] boolForKey:@"autoKey"]){
        NSData *pubKey = [[RSA sharedInstance] getPublicKeyBits];
        NSString *pubKeyAsString = [pubKey asBase64EncodedString];
        if (pubKeyAsString){
            [environment setObject:pubKeyAsString forKey:@"pubkey"];
        }
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"apnToken"]){
        NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"apnToken"];
        [environment setObject:deviceToken forKey:@"apndevicetoken"];
    }
    
    @try {
        NSString *enviromentAsString = [environment yajl_JSONString];
        
        //NSLog(@"HCLinccer updateEnvironment Dictionary: - %@", environment);

        if (USES_DEBUG_MESSAGES) { NSLog(@"HCLinccer updateEnvironment: %@", enviromentAsString); }
        
        if ([enviromentAsString length] <= 2) {
            NSLog(@"HCLinccer ERROR: updateEnvironment: environment string too short '%@'", enviromentAsString);
        }
        
        NSData * myPayLoad = [enviromentAsString dataUsingEncoding:NSUTF8StringEncoding];
        // NSLog(@"myPayLoad retaincount=%d", [myPayLoad retainCount]);
        
        self.envUpdateId = [httpClient putURI:[uri stringByAppendingPathComponent:@"/environment"]
                   payload: myPayLoad
                   success:@selector(httpConnection:didUpdateEnvironment:)];
        
        self.lastEnvironmentupdate = [[NSDate alloc] init];
    }
    @catch (NSException *e) {
        if (USES_DEBUG_MESSAGES, YES) { NSLog(@"HCLinccer updateEnvironment execption : %@", e); }
        else { NSLog(@"%@", e); }
    }
    
    [environment release];
}

- (void)cancelAllRequestsKeepPeek {
	[httpClient cancelAllRequests];
    self.linccingId = nil;
    
    [self peek];
}

- (void)cancelAllRequestsIncludingPeek {
	[httpClient cancelAllRequests];
    self.linccingId = nil;
    self.peekId = nil;
}

- (void)peek {
    if (self.peekId != nil) {
        if (USES_DEBUG_MESSAGES) {NSLog(@"HCLinccer: peek request refused, a peek request is still open");}
        return;
    } else {
        if (USES_DEBUG_MESSAGES) {NSLog(@"HCLinccer: new peek request");}
    }
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
	[httpClient cancelAllRequests];
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