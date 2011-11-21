//
//  ViewController.h
//  Hoccer Test
//
//  Created by Philip Brechler on 21.11.11.
//  Copyright (c) 2011 Hoccer GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Hoccer.h"

@interface ViewController : UIViewController <HCLinccerDelegate> {
    HCLinccer *linccer;
}

@property (nonatomic, retain) HCLinccer *linccer;

- (IBAction)hoccData:(id)sender;
- (NSDictionary *)dataDescription;

@end
