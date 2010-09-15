//
//  HoccerGeoStorage.h
//  HoccerAPI
//
//  Created by Robert Palmer on 14.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "HttpClient.h"
#import "LocationController.h"
#import "HCGeoStorageDelegate.h"


@interface HCGeoStorage : NSObject {
	LocationController *environmentController;
	HttpClient *httpClient;
	
	id <HCGeoStorageDelegate> delegate;
}

@property (assign) id <HCGeoStorageDelegate> delegate;
@property (readonly) CLLocation *location;

- (void)store: (NSDictionary *)data;
- (void)searchNearby;

@end
