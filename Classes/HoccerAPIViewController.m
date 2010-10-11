//
//  HoccerAPIViewController.m
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HoccerAPIViewController.h"

@interface HoccerAPIViewController ()

- (void)log: (NSString *)message;

@end



@implementation HoccerAPIViewController
@synthesize input, logger;


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
	
	hoccer = [[HCClient alloc] initWithApiKey:@"123456789" secret:@"secret111"];
	hoccer.delegate = self;
}

- (IBAction)send: (id)sender {
	NSString *message = input.text;
	NSDictionary *payload = [NSDictionary dictionaryWithObject:message forKey:@"message"];
	[hoccer send:payload withMode:HCTransferModeOneToOne];
}

- (IBAction)receive: (id)sender {
	[hoccer receiveWithMode:HCTransferModeOneToOne];
}

- (IBAction)clearLog: (id)sender {
	self.logger.text = @"";
}

#pragma mark -
#pragma mark Hoccer Delegate Methods

- (void)clientDidRegister: (HCClient *)hoccer; {
	[self log:NSStringFromSelector(_cmd)];
	NSLog(@"registered");
}

- (void) client:(HCClient *)hoccer didSendDataWithInfo:(NSDictionary *)info {
	[self log:[NSString stringWithFormat:@"%@\n%@", NSStringFromSelector(_cmd), info]];
	NSLog(@"send something");
}

- (void)client: (HCClient *)hoccer didReceiveData: (NSArray *)data {
	[self log:[NSString stringWithFormat:@"%@\n%@", NSStringFromSelector(_cmd), data]];

	NSLog(@"hoccer did receive: %@", data);
}

- (void)client: (HCClient *)hoccer didFailWithError: (NSError *)error; {
	[self log:[NSString stringWithFormat:@"%@\n%@", NSStringFromSelector(_cmd), error]];

	NSLog(@"error %@", error);
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.input resignFirstResponder];
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

- (void) log:(NSString *)message {
	if ([logger.text length] == 0) {
		logger.text = message;
	} else {
		logger.text = [NSString stringWithFormat:@"%@\n\n%@", logger.text, message];
	}
}


- (void)dealloc {
	[hoccer release];
    [super dealloc];
}

@end
