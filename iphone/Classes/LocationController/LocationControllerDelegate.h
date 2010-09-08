//
//  LocationControllerDelegate.h
//  Hoccer
//
//  Created by Robert Palmer on 14.04.10.
//  Copyright 2010 Art+Com AG. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LocationController;


@protocol LocationControllerDelegate <NSObject>

- (void) locationControllerDidUpdateLocation: (LocationController *)controller; 

@end
