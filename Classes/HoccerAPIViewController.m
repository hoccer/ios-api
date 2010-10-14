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
	
	linccer = [[HCLinccer alloc] initWithApiKey:@"123456789" secret:@"secret111"];
	linccer.delegate = self;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.input resignFirstResponder];
}

- (IBAction)send: (id)sender {
	NSString *message = input.text;
	NSDictionary *payload = [NSDictionary dictionaryWithObject:message forKey:@"message"];
	[linccer send:payload withMode:HCTransferModeOneToOne];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[self log:@"send"];
}

- (IBAction)receive: (id)sender {
	[linccer receiveWithMode:HCTransferModeOneToOne];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[self log:@"receive"];
}

- (IBAction)clearLog: (id)sender {
	self.logger.text = @"";
}

- (void)terminate {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[linccer disconnect];
}


#pragma mark -
#pragma mark Hoccer Delegate Methods

- (void)linccerDidRegister: (HCLinccer *)aLinccer; {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self log:NSStringFromSelector(_cmd)];
	NSLog(@"registered");
}

- (void)linccer:(HCLinccer *)aLinccer didSendDataWithInfo:(NSDictionary *)info {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self log:[NSString stringWithFormat:@"%@\n%@", NSStringFromSelector(_cmd), info]];
	NSLog(@"send something");
}

- (void)linccer: (HCLinccer *)aLinccer didReceiveData: (NSArray *)data {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self log:[NSString stringWithFormat:@"%@\n%@", NSStringFromSelector(_cmd), data]];

	NSLog(@"hoccer did receive: %@", data);
}

- (void)linccer: (HCLinccer *)aLinccer didFailWithError: (NSError *)error; {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self log:[NSString stringWithFormat:@"%@\n%@", NSStringFromSelector(_cmd), error]];

	NSLog(@"error %@", error);
}

- (void)linccerDidUnregister: (HCLinccer *)aLinccer {
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
	[linccer release];
    [super dealloc];
}

@end
