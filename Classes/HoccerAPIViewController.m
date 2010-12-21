//  Copyright (C) 2010, Hoccer GmbH Berlin, Germany <www.hoccer.com>
//  
//  These coded instructions, statements, and computer programs contain
//  proprietary information of Linccer GmbH Berlin, and are copy protected
//  by law. They may be used, modified and redistributed under the terms
//  of GNU General Public License referenced below. 
//  
//  Alternative licensing without the obligations of the GPL is
//  available upon request.
//  
//  GPL v3 Licensing:
    
//  This file is part of the "Linccer iOS-API".
    
//  Linccer iOS-API is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
    
//  Linccer iOS-API is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
    
//  You should have received a copy of the GNU General Public License
//  along with Linccer iOS-API. If not, see <http://www.gnu.org/licenses/>.
//
//  HoccerAPIViewController.m
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "HoccerAPIViewController.h"
#import "SandboxKeys.h"

@interface HoccerAPIViewController ()

- (void)log: (NSString *)message;

@end



@implementation HoccerAPIViewController
@synthesize input, logger;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	
	linccer = [[HCLinccer alloc] initWithApiKey:SANDBOX_APIKEY	secret:SANDBOX_SECRET];
	linccer.delegate = self;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.input resignFirstResponder];
}

- (IBAction)send: (id)sender {
	NSString *message = input.text;
	NSDictionary *payload = [NSDictionary dictionaryWithObject:message forKey:@"message"];
	[linccer send:payload withMode:HCTransferModeOneToMany];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[self log:@"send"];
}

- (IBAction)receive: (id)sender {
	[linccer receiveWithMode:HCTransferModeOneToMany];
	
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

- (void)reactivate {
	[linccer reactivate];
}


#pragma mark -
#pragma mark Hoccer Delegate Methods

- (void)linccerDidRegister: (HCLinccer *)aLinccer; {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self log:NSStringFromSelector(_cmd)];
	NSLog(@"registered");
}

- (void)linccer:(HCLinccer *)aLinccer didSendData:(NSArray *)data {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self log:[NSString stringWithFormat:@"%@\n%@", NSStringFromSelector(_cmd), data]];
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
