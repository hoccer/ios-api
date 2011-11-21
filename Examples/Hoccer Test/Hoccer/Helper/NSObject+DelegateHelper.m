//
//  NSObject+DelegateHelper.m
//  Hoccer
//
//  Created by Robert Palmer on 07.09.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSObject+DelegateHelper.h"


@implementation NSObject (DelegateHelper)

- (id)checkAndPerformSelector: (SEL)aSelector  
{
	if (![self respondsToSelector:aSelector]) {
		return nil;
	}
	
	return [self performSelector:aSelector];
}

- (id)checkAndPerformSelector: (SEL)aSelector withObject: (id)aObject  
{
	if (![self respondsToSelector:aSelector]) {
		return nil;
	}
	
	return [self performSelector:aSelector withObject:aObject];
}

- (id)checkAndPerformSelector: (SEL)aSelector withObject: (id)firstObject withObject: (id)secondObject  
{
	if (![self respondsToSelector:aSelector]) {
		return nil;
	}
	
	return [self performSelector:aSelector withObject:firstObject withObject: secondObject];
}



@end
