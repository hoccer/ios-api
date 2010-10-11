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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	
	hoccer = [[HCClient alloc] initWithApiKey:@"123456789" secret:@"secret111"];
	hoccer.delegate = self;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.input resignFirstResponder];
}

- (IBAction)send: (id)sender {
	NSString *message = input.text;
	NSDictionary *payload = [NSDictionary dictionaryWithObject:message forKey:@"message"];
	[hoccer send:payload withMode:HCTransferModeOneToOne];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[self log:@"send"];
}

- (IBAction)receive: (id)sender {
	[hoccer receiveWithMode:HCTransferModeOneToOne];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[self log:@"receive"];
}

- (IBAction)clearLog: (id)sender {
	self.logger.text = @"";
}

- (void)terminate {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[hoccer disconnect];
}


#pragma mark -
#pragma mark Hoccer Delegate Methods

- (void)clientDidRegister: (HCClient *)hoccer; {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self log:NSStringFromSelector(_cmd)];
	NSLog(@"registered");
}

- (void) client:(HCClient *)hoccer didSendDataWithInfo:(NSDictionary *)info {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self log:[NSString stringWithFormat:@"%@\n%@", NSStringFromSelector(_cmd), info]];
	NSLog(@"send something");
}

- (void)client: (HCClient *)hoccer didReceiveData: (NSArray *)data {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self log:[NSString stringWithFormat:@"%@\n%@", NSStringFromSelector(_cmd), data]];

	NSLog(@"hoccer did receive: %@", data);
}

- (void)client: (HCClient *)hoccer didFailWithError: (NSError *)error; {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self log:[NSString stringWithFormat:@"%@\n%@", NSStringFromSelector(_cmd), error]];

	NSLog(@"error %@", error);
}

- (void)clientDidUnregister: (HCClient *)hoccer {
	[self log:NSStringFromSelector(_cmd)];
	NSLog(@"unregistered hoccer");
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
