//
//  GeostoreSampleViewController.h
//  GeostoreSample
//
//  Created by Robert Palmer on 15.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Hoccer/Hoccer.h>

@interface GeostoreSampleViewController : UIViewController <MKMapViewDelegate> {
	MKMapView *mapView;
}

@property (retain, nonatomic) IBOutlet MKMapView *mapView;

- (IBAction)addLocationNote: (id)sender;
- (IBAction)query: (id)sender;
- (IBAction)queryByEnvironment: (id)sender;

@end

