//
//  HCError.h
//  Hoccer
//
//  Created by Pavel on 22.02.13.
//  Copyright (c) 2013 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HCError : NSError

- (HCError*) init;
- (HCError*) initWithErrorCode: (NSInteger) errorCode errorText:(NSString*) errorText;

@end
