//
//  HoccerDelegate.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Hoccer;

@protocol HoccerDelegate

- (void)hoccerDidBecomeReady: (Hoccer *)hoccer;

- (void)hoccerDidSendData: (Hoccer *)hoccer;
- (void)hoccerDidReceiveData: (Hoccer *)hoccer;

@end
