//
//  GeostoreSampleAppDelegate.h
//  GeostoreSample
//
//  Created by Robert Palmer on 15.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GeostoreSampleViewController;

@interface GeostoreSampleAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    GeostoreSampleViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet GeostoreSampleViewController *viewController;

@end

