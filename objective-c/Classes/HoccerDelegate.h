//
//  HoccerDelegate.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Hoccer;

@protocol HoccerDelegate <NSObject>

- (void)hoccerDidRegister: (Hoccer *)hoccer;
- (void)hoccerDidSendData: (Hoccer *)hoccer;
- (void)hoccer: (Hoccer *)hoccer didReceiveData: (NSData *)data;
- (void)hoccer: (Hoccer *)hoccer didFailWithError: (NSError *)error;

@end
