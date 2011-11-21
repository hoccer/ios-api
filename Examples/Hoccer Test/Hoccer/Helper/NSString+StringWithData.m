//
//  NSString+StringWithData.m
//  Hoccer
//
//  Created by Robert Palmer on 06.10.09.
//  Copyright 2009 ART+COM. All rights reserved.
//

#import "NSString+StringWithData.h"


@implementation NSString (StringWithData)

+ (NSString *)stringWithData: (NSData *)data usingEncoding: (NSStringEncoding)encoding
{
	NSString *string = [[NSString alloc] initWithData:data encoding:encoding];
	
	return [string autorelease];
}


@end
