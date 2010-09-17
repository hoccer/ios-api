//
//  LocationControllerDelegate.h
//  Hoccer
//
//  Created by Robert Palmer on 14.04.10.
//  Copyright 2010 Art+Com AG. All rights reserved.


#import <UIKit/UIKit.h>
@class HCEnvironmentManager;


@protocol HCEnvironmentManagerDelegate <NSObject>

- (void) environmentManagerDidUpdateEnvironment: (HCEnvironmentManager *)manager; 

@end
