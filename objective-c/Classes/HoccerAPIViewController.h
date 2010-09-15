//
//  HoccerAPIViewController.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HoccerDelegate.h"
@class HCClient;

@interface HoccerAPIViewController : UIViewController <HoccerDelegate> {
	HCClient *hoccer;
}

- (IBAction)send: (id)sender;
- (IBAction)receive: (id)sender;

@end

