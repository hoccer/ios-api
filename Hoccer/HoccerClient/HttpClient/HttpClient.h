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
//  HttpClient.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HttpConnection.h"

#define HttpErrorDomain @"HttpErrorDomain"
#define HttpClientRequestUri @"HttpClientRequestUri"

@interface HttpClient : NSObject {
	NSString *baseURL;
	
	NSMutableDictionary *connections;
	
	id target;
	
	NSString *userAgent;
}

@property (assign) id target;
@property (retain, nonatomic) NSString *userAgent;

- (id)initWithURLString: (NSString *)url;
- (NSString *)getURI: (NSString *)uri success: (SEL)success;
- (NSString *)putURI: (NSString *)uri payload: (NSData *)payload success: (SEL)success;
- (NSString *)postURI: (NSString *)uri payload: (NSData *)payload success: (SEL)success;
- (NSString *)deleteURI: (NSString *)uri success: (SEL)success;
- (NSString *)requestMethod: (NSString *)method URI: (NSString *)uri payload: (NSData *)payload success: (SEL)success;
- (NSString *)requestMethod:(NSString *)method absoluteURL:(NSString *)url payload:(NSData *)payload success:(SEL)success;
- (NSString *)requestMethod:(NSString *)method URI:(NSString *)url payload:(NSData *)payload header: (NSDictionary *)headers success:(SEL)success;
- (NSString *)requestMethod:(NSString *)method absoluteURI:(NSString *)url payload:(NSData *)payload header: (NSDictionary *)headers success:(SEL)success;

- (void)cancelAllRequest;
- (void)cancelRequest: (NSString *)uri;
- (BOOL)hasActiveRequest;

@end