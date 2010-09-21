//
//  HCMapView.m
//  GeostoreSample
//
//  Created by Robert Palmer on 21.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HCMapView.h"


@interface SampleAnnotation : NSObject <MKAnnotation>
{
	NSDictionary *dict;
}

- (id)initWithDictionary: (NSDictionary *)dictionary;

@end

@implementation SampleAnnotation

- (id)initWithDictionary: (NSDictionary *)dictionary {
	self = [super init];
	if (self != nil) {
		dict = [dictionary retain];
	}
	
	return self;
}

- (void) dealloc {
	[dict release];
	[super dealloc];
}

- (CLLocationCoordinate2D) coordinate {
	CLLocationCoordinate2D coord;
	coord.longitude = [[[[dict objectForKey:@"environment"] objectForKey:@"gps"] objectForKey:@"longitude"] doubleValue];
	coord.latitude = [[[[dict objectForKey:@"environment"] objectForKey:@"gps"] objectForKey:@"latitude"] doubleValue];
	
	return coord;
}

- (NSString *) title {
	return [[dict objectForKey:@"params"] objectForKey:@"note"];
}

@end


@implementation HCMapView

-(void) awakeFromNib {
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	[locationManager startUpdatingLocation];
	
	geostorage = [[HCGeoStorage alloc] init];
	geostorage.delegate = self;
	
	UIGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self 
																					action:@selector(addPin:)];
	[self addGestureRecognizer:recognizer];
	[recognizer release];
	
}

- (void) dealloc {
	[locationManager release];
	[geostorage release];
}


- (MKAnnotationView *) viewForAnnotation:(id <MKAnnotation>)annotation {
	if (![annotation isKindOfClass:[SampleAnnotation class]]) {
		return [super viewForAnnotation:annotation];
	}
	
	static NSString * annotationName = @"SimpleAnnotation";
	
	MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self dequeueReusableAnnotationViewWithIdentifier:annotationName];
	if (annotationView == nil) {
		annotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationName] autorelease];
		annotationView.pinColor = MKPinAnnotationColorGreen;
		annotationView.animatesDrop = YES;
		annotationView.canShowCallout = YES;
	} else {
		annotationView.annotation = annotation;
	}
	
	annotationView.animatesDrop = YES;
	
	return annotationView;
	
}



#pragma mark -
#pragma mark LocationManager Delegate Methods
- (void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation  {
	MKCoordinateRegion region = MKCoordinateRegionMake(newLocation.coordinate, MKCoordinateSpanMake(0.02, 0.02));
	[self setRegion:region animated:YES];
	
	[geostorage searchNearby];
	[locationManager stopUpdatingLocation];
}

- (void)addPin: (UILongPressGestureRecognizer *)recognizer {	
	if (recognizer.state != UIGestureRecognizerStateBegan) {
		return;
	}
	
	CLLocationCoordinate2D location = [self convertPoint: [recognizer locationInView:self] 
									   toCoordinateFromView:self];
	
	[geostorage storeProperties:[NSDictionary dictionaryWithObject:@"wooo" forKey:@"note"] 
					 atLocation:location forTimeInterval: HCGeoStorageDefaultStorageTimeInterval];
	
	[geostorage searchInRegion:self.region];
}

#pragma mark -
#pragma mark Geostorage Delegate Methods
- (void)geostorage: (HCGeoStorage *)geoStorage didFinishStoringWithId: (NSString *)urlId {
	NSLog(@"stored with id: %@", urlId);
}

- (void)geostorage: (HCGeoStorage *)geoStorage didFindItems: (NSArray *)items {
	[self removeAnnotations: self.annotations];
	
	for (NSDictionary *item in items) {
		SampleAnnotation *annotation = [[SampleAnnotation alloc] initWithDictionary: item];
		[self addAnnotation:annotation];
	}
}

- (void)geostorage: (HCGeoStorage *)geoStorage didFailWithError: (NSError *)error {
	NSLog(@"error: %@", error);
}



@end
