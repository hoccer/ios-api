//
//  HoccerGeoStorage.h
//  HoccerAPI
//
//  Created by Robert Palmer on 14.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpClient.h"
#import "LocationController.h"

@interface HoccerGeoStorage : NSObject {
	LocationController *environmentController;
	HttpClient *httpClient;
}

- (void)store: (NSData *)data;
- (void)search;

@end
