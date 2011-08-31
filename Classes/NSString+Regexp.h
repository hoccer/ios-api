//
//  NSObject+Regexp.h
//  Hoccer
//
//  Created by Robert Palmer on 23.09.09.
//  Copyright 2009 ART+COM. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Regexp) 

- (BOOL)matches: (NSString *)pattern;
- (BOOL)matchesFeaturePattern: (NSString *)featurePattern;

- (BOOL)startsWith: (NSString *)startString;
- (BOOL)endsWith: (NSString *)endString;

- (BOOL)contains: (NSString *)substring;

@end
