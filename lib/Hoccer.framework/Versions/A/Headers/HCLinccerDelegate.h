//
//  HoccerDelegate.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH, Berlin. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HCLinccer;

@protocol HCLinccerDelegate <NSObject>
@optional
- (void)linccerDidRegister: (HCLinccer *)linccer;
- (void)linccer: (HCLinccer *)linccer didSendDataWithInfo: (NSDictionary *)info ;
- (void)linccer: (HCLinccer *)linncer didReceiveData: (NSArray *)data;
- (void)linccer: (HCLinccer *)linccer didFailWithError: (NSError *)error;
- (void)linccerDidUnregister: (HCLinccer *)linccer;

@end
