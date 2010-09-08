//
//  HoccerAPIAppDelegate.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HoccerAPIViewController;

@interface HoccerAPIAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    HoccerAPIViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet HoccerAPIViewController *viewController;

@end

