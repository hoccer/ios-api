//
//  HttpConnection.h
//  HoccerAPI
//
//  Created by Robert Palmer on 14.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HttpConnection : NSObject {
	NSString *uri;
	
	NSURLRequest *request;
	NSHTTPURLResponse *response;
}

@property (copy) NSString *uri;
@property (retain, nonatomic) NSURLRequest *request;
@property (retain, nonatomic) NSHTTPURLResponse *response;

@end
