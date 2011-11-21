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
//  HoccerGeoStorage.h
//  HoccerAPI
//
//  Created by Robert Palmer on 14.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "HCAuthenticatedHttpClient.h"
#import "HCEnvironmentManager.h"
#import "HCGeoStorageDelegate.h"

#define HCGeoStorageDefaultStorageTimeInterval -1


@interface HCGeoStorage : NSObject {
	HCEnvironmentManager *environmentController;
	HCAuthenticatedHttpClient *httpClient;
	
	id <HCGeoStorageDelegate> delegate;
}

@property (assign) id <HCGeoStorageDelegate> delegate;
@property (readonly) CLLocation *location;

- (id) initWithApiKey: (NSString *)key secret: (NSString *)secret;

- (void)storeProperties: (NSDictionary *)dictionary;
- (void)storeProperties: (NSDictionary *)dictionary forTimeInterval: (NSTimeInterval)seconds;
- (void)storeProperties: (NSDictionary *)dictionary atLocation: (CLLocationCoordinate2D)location forTimeInterval: (NSTimeInterval)seconds; 

- (void)searchNearby;
- (void)searchInRegion: (MKCoordinateRegion)region;
- (void)searchAtLocation: (CLLocationCoordinate2D)location radius: (CLLocationDistance)radius;

- (void)searchNearbyWithConditions: (NSDictionary *)conditions;
- (void)searchInRegion: (MKCoordinateRegion)region withConditions: (NSDictionary *)conditions;
- (void)searchAtLocation: (CLLocationCoordinate2D)location radius: (CLLocationDistance)radius withConditions: (NSDictionary *)conditions;

- (void)deleteRecordWithId: (NSString *)recordId;

@end
