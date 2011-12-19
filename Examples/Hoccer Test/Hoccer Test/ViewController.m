//
//  ViewController.m
//  Hoccer Test
//
//  Created by Philip Brechler on 21.11.11.
//  Copyright (c) 2011 Hoccer GmbH. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

@synthesize linccer;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Setting up Hoccer Linccer
    
    linccer = [[HCLinccer alloc] initWithApiKey:@"YOUR_API_KEY" secret: @"YOUR_API_SECRET" sandboxed:NO];
    linccer.delegate = self;
    
    //Setting the client name
    
    NSMutableDictionary *userInfo = [[linccer.userInfo mutableCopy] autorelease];
    if (userInfo == nil) {
        userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    
    [userInfo setObject:@"<ourlittletest>" forKey:@"client_name"];
    
    linccer.userInfo = userInfo;

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark HCLinccer Delegate Methods
- (void)linccerDidRegister: (HCLinccer *)aLinccer {
    NSLog(@"ready for transfering data");
}


- (void)linccer: (HCLinccer *)aLinccer didSendDataWithInfo: (NSDictionary *)info  {
    NSLog(@"successfully send something %@", info);
}

- (void)linccer: (HCLinccer *)aLinccer didReceiveData: (NSArray *)data {
    NSLog(@"received data: %@", data);
}

- (void)linccer: (HCLinccer *)aLinccer didFailWithError: (NSError *)error {
	NSLog(@"failed with error: %@", error);
}

- (IBAction)hoccData:(id)sender {
    NSDictionary *content = [NSDictionary dictionaryWithObjectsAndKeys: [NSArray arrayWithObject:self.dataDescription], @"data", nil];
    
    [linccer send:content withMode:HCTransferModeOneToMany];
}

- (NSDictionary *) dataDescription {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setObject:@"image/jpeg" forKey:@"type"];
	[dict setObject:@"http://hoccer.com/wp-content/themes/hoccer/images/logo.jpg" forKey:@"uri"];
    
	return dict;
}

@end
