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
//  HCFileCache.m
//  HoccerAPI
//
//  Created by Robert Palmer on 24.11.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <YAJLiOs/YAJL.h>
#import "HCFileCache.h"
#import "RSA.h"
#import "Crypto.h"
#import "NSDictionary+CSURLParams.h"
#import "NSString+URLHelper.h"
#import "NSData+CommonCrypto.h"

#define FILECACHE_URI @"https://filecache.hoccer.com/v3"
#define FILECACHE_SANDBOX_URI @"https://filecache-experimental.hoccer.com/v3"
//#define FILECACHE_SANDBOX_URI @"https://filecache-sandbox.hoccer.com/v3"

@implementation HCFileCache

@synthesize delegate;
@synthesize cryptor;

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret {
	return [self initWithApiKey:key secret:secret sandboxed:NO];
}

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret sandboxed: (BOOL)sandbox {
	self = [super init];
	if (self != nil) {
		if (sandbox) {
			httpClient = [[HCAuthenticatedHttpClient alloc] initWithURLString:FILECACHE_SANDBOX_URI];
		} else {
			httpClient = [[HCAuthenticatedHttpClient alloc] initWithURLString:FILECACHE_URI];
		}
		
		httpClient.apiKey = key;
		httpClient.secret = secret;
		httpClient.target = self;
	}
	
	return self;
}


#pragma mark -
#pragma mark Metods for Sending
- (NSString *)cacheData: (NSData *)data withFilename: (NSString*)filename forTimeInterval: (NSTimeInterval)interval {
	    
    NSDictionary *params = [NSDictionary dictionaryWithObject:[[NSNumber numberWithDouble:interval] stringValue] forKey:@"expires_in"];
	
	NSString *contentDisposition = [NSString stringWithFormat:@"attachment; filename=\"%@\"", filename];
	NSDictionary *headers = [NSDictionary dictionaryWithObject:contentDisposition forKey:@"Content-Disposition"]; 
	
	NSString *urlName = [@"/" stringByAppendingString:[NSString stringWithUUID]];
	NSString *uri = [urlName stringByAppendingQuery:[params URLParams]];
		
	return [httpClient requestMethod:@"PUT" URI:uri payload:data header:headers success:@selector(httpConnection:didSendData:)];
}

- (NSString *)cacheData: (NSData *)data withFilename: (NSString*)filename forTimeInterval: (NSTimeInterval)interval encrypted:(BOOL)encrypted{
    if (!encrypted) {
        return [self cacheData:data withFilename:filename forTimeInterval:interval];
    }
    else {

        NSString *key = [[NSUserDefaults standardUserDefaults] stringForKey:@"encryptionKey"];
            
        self.cryptor = [[[AESCryptor alloc] initWithKey:key] autorelease];
        
        [self.cryptor encrypt:data];
        return [self cacheData:data withFilename:filename forTimeInterval:interval];
    }
}

#pragma mark -
#pragma mark Methods for Fetching
- (NSString *)load: (NSString *)url {
	return [httpClient requestMethod:@"GET" absoluteURL:url payload:nil success:@selector(httpConnection:didReceiveData:)];
}

#pragma mark -
#pragma mark HttpConnection Delegate Methods

- (void)httpConnection: (HttpConnection *)connection didSendData: (NSData *)data {
	if ([delegate respondsToSelector:@selector(fileCache:didUploadFileToURI:)]) {
		NSString *body = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		[delegate fileCache:self didUploadFileToURI:body];
	}
}

- (void)httpConnection:(HttpConnection *)connection didUpdateDownloadPercentage: (NSNumber *)percentage {
	if ([delegate respondsToSelector:@selector(fileCache:didUpdateProgress:forURI:)]) {
		[delegate fileCache:self didUpdateProgress:percentage forURI: connection.uri];
	}
}

- (void)httpConnection:(HttpConnection *)connection didFailWithError: (NSError *)error {
	if ([delegate respondsToSelector:@selector(fileCache:didFailWithError:forURI:)]) {
		[delegate fileCache:self didFailWithError:error forURI:connection.uri];
	}
}

- (void)httpConnection:(HttpConnection *)connection didReceiveData: (NSData *)data {    
    if ([delegate respondsToSelector:@selector(fileCache:didReceiveResponse:withDownloadedData:forURI:)]) {
		[delegate fileCache: self didReceiveResponse:connection.response withDownloadedData: data forURI: connection.uri];
	}
}

- (void)cancelTransferWithURI: (NSString *)transferUri {
	[httpClient cancelRequest:transferUri];
}

#pragma mark -
#pragma mark Getter
-(id<Cryptor>)cryptor {
    if (cryptor == nil) {
        cryptor = [[AESCryptor alloc] initWithKey:@"secret"];
    }
    
    return cryptor;
}


- (void)dealloc {
	httpClient.target = nil;
	[httpClient release];
    [cryptor release];
	
	[super dealloc];
}

@end
