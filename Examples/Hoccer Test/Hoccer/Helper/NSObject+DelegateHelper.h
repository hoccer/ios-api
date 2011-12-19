//
//  NSObject+DelegateHelper.h
//  Hoccer
//
//  Created by Robert Palmer on 07.09.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSObject (DelegateHelper)

- (id)checkAndPerformSelector: (SEL)selector;
- (id)checkAndPerformSelector: (SEL)aSelector withObject: (id)aObject;
- (id)checkAndPerformSelector: (SEL)aSelector withObject: (id)firstObject withObject: (id)secondObject;

@end
