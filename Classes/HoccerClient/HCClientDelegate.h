//
//  HoccerDelegate.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HCClient;

@protocol HCClientDelegate <NSObject>

- (void)clientDidRegister: (HCClient *)hoccer;
- (void)clientDidSendData: (HCClient *)hoccer;
- (void)client: (HCClient *)client didReceiveData: (NSData *)data;
- (void)client: (HCClient *)client didFailWithError: (NSError *)error;

@end
