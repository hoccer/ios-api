//
//  HCMapView.h
//  GeostoreSample
//
//  Created by Robert Palmer on 21.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <Hoccer/Hoccer.h>

@interface HCMapView : MKMapView <CLLocationManagerDelegate, HCGeoStorageDelegate> {
	CLLocationManager *locationManager;
	HCGeoStorage *geostorage;
}

@end
