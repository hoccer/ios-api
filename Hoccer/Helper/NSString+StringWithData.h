//
//  NSString+StringWithData.h
//  Hoccer
//
//  Created by Robert Palmer on 06.10.09.
//  Copyright 2009 ART+COM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface NSString (StringWithData) 

+ (NSString *)stringWithData: (NSData *)data usingEncoding: (NSStringEncoding) encoding;

@end
