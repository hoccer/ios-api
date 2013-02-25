//
//  HoccerError.m
//  Hoccer
//
//  Created by Pavel on 22.02.13.
//  Copyright (c) 2013 Hoccer GmbH. All rights reserved.
//

#import "HCError.h"

@implementation HCError


- (HCError*) init {
    if ( self = [super init] ) {
    }
    return self;
}


- (HCError*) initWithErrorCode: (NSInteger) errorCode errorText:(NSString*) errorText {
    
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:errorText forKey:NSLocalizedDescriptionKey];
    
    if ( self = [super initWithDomain:@"Hoccer" code:errorCode userInfo:errorDetail] ) {
    }
    return self;
}

@end
