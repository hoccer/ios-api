//
//  HoccerDelegate.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH, Berlin. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HCClient;

@protocol HCClientDelegate <NSObject>
@optional
- (void)clientDidRegister: (HCClient *)hoccer;
- (void)client: (HCClient *)hoccer didSendDataWithInfo: (NSDictionary *)info ;
- (void)client: (HCClient *)client didReceiveData: (NSArray *)data;
- (void)client: (HCClient *)client didFailWithError: (NSError *)error;
- (void)clientDidUnregister: (HCClient *)hoccer;

@end
