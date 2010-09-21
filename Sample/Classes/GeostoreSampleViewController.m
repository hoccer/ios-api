//
//  GeostoreSampleViewController.m
//  GeostoreSample
//
//  Created by Robert Palmer on 15.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "GeostoreSampleViewController.h"


@implementation GeostoreSampleViewController
@synthesize mapView;

- (void)viewDidLoad {
    [super viewDidLoad];
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
	[mapView release];
	
    [super dealloc];
}

- (void) mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
	// [self query:self];
}

#pragma mark -
#pragma mark Action Methods
- (IBAction)addLocationNote: (id)sender {	
//	NSDictionary *note = [NSDictionary dictionaryWithObjectsAndKeys:
//						  @"Hoccer API was here", @"note", nil];
//	
//	[geostorage storeProperties: note];
}

- (IBAction)query: (id)sender {
//	[geostorage searchInRegion: mapView.region];
}

- (IBAction)queryByEnvironment: (id)sender {
//	[geostorage searchNearby];
}

@end
