//
//  HoccerGeoStorageDelegate.h
//  HoccerAPI
//
//  Created by Robert Palmer on 14.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HCGeoStorage;

@protocol HCGeoStorageDelegate <NSObject>

@optional
- (void)geostorageDidStore: (HCGeoStorage *)geoStorage;
- (void)geostorage: (HCGeoStorage *)geoStorage didFindItems: (NSArray *)items;
- (void)geostorage: (HCGeoStorage *)geoStorage didFailWithError: (NSError *)error;

@end
