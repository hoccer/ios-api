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
//  Hoccer.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCLinccerDelegate.h"
#import "HCEnvironmentManagerDelegate.h"
#import "HCAuthenticatedHttpClient.h"

#define HoccerError @"HoccerError"

#define HCTransferModeOneToOne @"one-to-one"
#define HCTransferModeOneToMany @"one-to-many"

enum HoccerErrors {
	HoccerNoReceiverError = 1,
	HoccerNoSenderError
};

@class HttpClient;

@interface HCLinccer : NSObject <HCEnvironmentManagerDelegate> {
	@private
	HCEnvironmentManager *environmentController;
	HCAuthenticatedHttpClient *httpClient;

	NSString *uri;
	BOOL isRegistered;
	
	NSTimer *updateTimer;
	NSTimeInterval latency;
	id <HCLinccerDelegate> delegate;
}

@property (retain) HCEnvironmentManager* environmentController;
@property (assign) id <HCLinccerDelegate> delegate;
@property (assign) BOOL isRegistered;
@property (assign) NSTimeInterval latency;

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret;
- (id) initWithApiKey:(NSString *)key secret:(NSString *)secret sandboxed: (BOOL)sandbox;

- (void)send: (NSDictionary *)data withMode: (NSString *)mode;
- (void)receiveWithMode: (NSString *)mode;

- (void)reactivate;
- (void)disconnect;

- (BOOL)isLinccing;

- (void)cancelAllRequest;
- (NSString *)uuid;

- (void)updateEnvironment;

@end
