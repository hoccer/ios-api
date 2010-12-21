//
//  HoccerAPIViewController.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Hoccer.h"
@class HCLinccer;

@interface HoccerAPIViewController : UIViewController <HCLinccerDelegate> {
	HCLinccer *linccer;
	
	UITextField *input;
	UITextView *logger;
}

@property (retain, nonatomic) IBOutlet UITextField *input;
@property (retain, nonatomic) IBOutlet UITextView *logger;

- (IBAction)send: (id)sender;
- (IBAction)receive: (id)sender;
- (IBAction)clearLog: (id)sender;

- (void)terminate;
- (void)reactivate;

@end

