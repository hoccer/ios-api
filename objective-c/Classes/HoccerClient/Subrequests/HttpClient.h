//
//  HttpClient.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HttpClient : NSObject {
	NSString *baseURL;
	
	NSMutableDictionary *connections;
	id target;
}

@property (assign) id target;

- (id)initWithURLString: (NSString *)url;
- (void)getURI: (NSString *)uri success: (SEL)success;
- (void)putURI: (NSString *)uri payload: (NSData *)payload success: (SEL)success;
- (void)postURI: (NSString *)uri payload: (NSData *)payload success: (SEL)success;

@end
