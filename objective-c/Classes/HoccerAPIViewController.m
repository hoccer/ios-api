//
//  HoccerAPIViewController.m
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HoccerAPIViewController.h"
#import "HCClient.h"

@implementation HoccerAPIViewController



/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	
	hoccer = [[HCClient alloc] init];
	hoccer.delegate = self;
}

- (IBAction)send: (id)sender {
	NSData *data = [@"{\"inline\": \"Hallo\"}" dataUsingEncoding:NSUTF8StringEncoding];
	
	[hoccer send:data withMode:@"distribute"];
}

- (IBAction)receive: (id)sender {
	[hoccer receiveWithMode:@"distribute"];
}

#pragma mark -
#pragma mark Hoccer Delegate Methods

- (void)hoccerDidRegister: (HCClient *)hoccer; {
	NSLog(@"registered");
}

- (void)hoccerDidSendData: (HCClient *)hoccer; {
	NSLog(@"send something");
}

- (void)hoccer: (HCClient *)hoccer didReceiveData: (NSData *)data {
	NSLog(@"hoccer did receive: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
}

- (void)hoccer: (HCClient *)hoccer didFailWithError: (NSError *)error; {
	NSLog(@"error %@", error);
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
	[hoccer release];
    [super dealloc];
}

@end
