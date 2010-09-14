//
//  HoccerGeoStorageDelegate.h
//  HoccerAPI
//
//  Created by Robert Palmer on 14.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol HoccerGeoStorageDelegate

- (void)hoccerGeostorageDidStore: (HoccerGeoStorage *)geoStorage;
- (void)hoccerGeostorage: (HoccerGeoStorage *)geoStorage didFindItems: (NSArray *)items;
- (void)hoccerGeostorage: (HoccerGeoStorage *)geoStorage didFailWithError: (NSError *)error;


@end
