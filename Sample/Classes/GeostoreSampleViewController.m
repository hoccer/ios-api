//
//  GeostoreSampleViewController.m
//  GeostoreSample
//
//  Created by Robert Palmer on 15.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GeostoreSampleViewController.h"

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




@implementation GeostoreSampleViewController
@synthesize mapView;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	[locationManager startUpdatingLocation];
	
	geostorage = [[HCGeoStorage alloc] init];
	geostorage.delegate = self;
	
	UIGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self 
																					 action:@selector(addPin:)];
	[mapView addGestureRecognizer:recognizer];
	[recognizer release];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[geostorage release];
	[mapView release];
	[locationManager release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark LocationManager Delegate Methods
- (void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation  {
	MKCoordinateRegion region = MKCoordinateRegionMake(newLocation.coordinate, MKCoordinateSpanMake(0.02, 0.02));
	[mapView setRegion:region animated:YES];

	[geostorage searchNearby];
	[locationManager stopUpdatingLocation];
}

- (void)addPin: (UILongPressGestureRecognizer *)recognizer {	
	if (recognizer.state != UIGestureRecognizerStateBegan) {
		return;
	}
	
	CLLocationCoordinate2D location = [mapView convertPoint: [recognizer locationInView:mapView] 
									   toCoordinateFromView:mapView];
	
	[geostorage storeDictionary:[NSDictionary dictionaryWithObject:@"wooo" forKey:@"note"] 
					 atLocation:location forTimeInterval: HCGeoStorageDefaultStorageTimeInterval];
	
	[geostorage searchInRegion:mapView.region];
}




#pragma mark -
#pragma mark MapView Delegate Methods
- (MKAnnotationView *) mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation {
	static NSString * annotationName = @"SimpleAnnotation";
	
	MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[aMapView dequeueReusableAnnotationViewWithIdentifier:annotationName];
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

- (void) mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
	// [self query:self];
}

#pragma mark -
#pragma mark Geostorage Delegate Methods
- (void)geostorageDidSaveSuccessful: (HCGeoStorage *)geoStorage {
	
}

- (void)geostorage: (HCGeoStorage *)geoStorage didFindItems: (NSArray *)items {
	[mapView removeAnnotations: mapView.annotations];
	
	for (NSDictionary *item in items) {
		SampleAnnotation *annotation = [[SampleAnnotation alloc] initWithDictionary: item];
		[mapView addAnnotation:annotation];
	}
}

- (void)geostorage: (HCGeoStorage *)geoStorage didFailWithError: (NSError *)error {
	NSLog(@"error: %@", error);
}


#pragma mark -
#pragma mark Action Methods
- (IBAction)addLocationNote: (id)sender {	
	NSDictionary *note = [NSDictionary dictionaryWithObjectsAndKeys:
						  @"Hoccer API was here", @"note", nil];
	
	[geostorage store:note];
}

- (IBAction)query: (id)sender {
	[geostorage searchInRegion: mapView.region];
}

- (IBAction)queryByEnvironment: (id)sender {
	[geostorage searchNearby];
}

@end
