//
//  HoccerRegister.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HoccerRegister;

@protocol HoccerRegisterDelegate <NSObject>

- (void)hoccer: (HoccerRegister *)request didRegisterWithInfo: (NSDictionary *)info;

@end


@interface HoccerRegister : NSObject {
	NSMutableData *receivedData;
	NSURLConnection *connection;
	
	id <HoccerRegisterDelegate> deleate;
}

@property (assign) id <HoccerRegisterDelegate> delegate;

@end
