//
//  NSString+URLHelper.h
//  HoccerAPI
//
//  Created by Robert Palmer on 24.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (URLHelper)

- (NSString *) URLQuery;
- (NSString *) stringByRemovingQuery;
- (NSString *) stringByAppendingQuery: (NSString *)query;

- (NSString *) urlEncodeValue;
@end
