//
//  LocationController+FakeUuid.m
//  HoccerAPI
//
//  Created by Robert Palmer on 04.11.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "HCLinccer+FakeUuid.h"
#import "NSString+URLHelper.h"

@implementation HCLinccer (FakeUuid)

- (NSString *)uuid {
	return [NSString stringWithUUID];
}

@end
