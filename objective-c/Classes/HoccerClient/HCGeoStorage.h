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

@interface HCGeoStorage : NSObject {
	LocationController *environmentController;
	HttpClient *httpClient;
}

- (void)store: (NSDictionary *)data;
- (void)searchNearby;

@end
