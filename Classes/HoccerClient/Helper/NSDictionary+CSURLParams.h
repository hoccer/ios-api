//
//  NSDictionary+CSURLParams.h
//  HoccerAPI
//
//  Created by Robert Palmer on 24.09.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (CSURLParams)

+ (id)dictionaryWithURLParams: (NSString *)params;
- (NSString *)URLParams;

@end