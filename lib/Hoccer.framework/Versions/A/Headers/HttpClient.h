//
//  HttpClient.h
//  HoccerAPI
//
//  Created by Robert Palmer on 08.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HttpConnection.h"

#define HttpErrorDomain @"HttpErrorDomain"
#define HttpClientRequestUri @"HttpClientRequestUri"

@interface HttpClient : NSObject {
	NSString *baseURL;
	
	NSMutableDictionary *connections;
	BOOL canceled;
	
	id target;
	
	NSString *userAgent;
}

@property (assign) id target;
@property (retain) NSString *userAgent;

- (id)initWithURLString: (NSString *)url;
- (NSString *)getURI: (NSString *)uri success: (SEL)success;
- (NSString *)putURI: (NSString *)uri payload: (NSData *)payload success: (SEL)success;
- (NSString *)postURI: (NSString *)uri payload: (NSData *)payload success: (SEL)success;
- (NSString *)deleteURI: (NSString *)uri success: (SEL)success;
- (NSString *)requestMethod: (NSString *)method URI: (NSString *)uri payload: (NSData *)payload success: (SEL)success;
- (NSString *)requestMethod:(NSString *)method absoluteURL:(NSString *)url payload:(NSData *)payload success:(SEL)success;
- (NSString *)requestMethod:(NSString *)method URI:(NSString *)url payload:(NSData *)payload header: (NSDictionary *)headers success:(SEL)success;
- (NSString *)requestMethod:(NSString *)method absoluteURI:(NSString *)url payload:(NSData *)payload header: (NSDictionary *)headers success:(SEL)success;


- (void)cancelAllRequest;
- (void)cancelRequest: (NSString *)uri;

@end