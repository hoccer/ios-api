//
//  NSFileHandler+FileHelper.m
//  Hoccer
//
//  Created by Robert Palmer on 09.12.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import "NSFileManager+FileHelper.h"


@implementation NSFileManager (FileHelper)

- (NSString *)uniqueFilenameForFilename: (NSString *)theFilename inDirectory: (NSString *)directory {
	if (![[NSFileManager defaultManager] fileExistsAtPath: [directory stringByAppendingPathComponent:theFilename]]) {
		return theFilename;
	};
	
	NSString *ext = [theFilename pathExtension];
	NSString *baseFilename = [theFilename stringByDeletingPathExtension];
	
	NSInteger i = 1;
	NSString* newFilename = [NSString stringWithFormat:@"%@_%@", baseFilename, [[NSNumber numberWithInteger:i] stringValue]];
    if ((ext == nil) || (ext.length <= 0)) {
        ext = @"";
        //NSLog(@"empty ext 4");
    }
    newFilename = [newFilename stringByAppendingPathExtension:ext];
	while ([[NSFileManager defaultManager] fileExistsAtPath:[directory stringByAppendingPathComponent:newFilename]]) {
		newFilename = [NSString stringWithFormat:@"%@_%@", baseFilename, [[NSNumber numberWithInteger:i] stringValue]];
		newFilename = [newFilename stringByAppendingPathExtension:ext];
		
		i++;
	}
	
	return newFilename;
}

- (NSString *)contentDirectory {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
	
	if ([paths count] < 1) {
		@throw [NSException exceptionWithName:@"directoryException" reason:@"could not locate document directory" userInfo:nil];
	}
	
	NSString *documentsDirectoryUrl = [paths objectAtIndex:0];
	if (![[NSFileManager defaultManager] fileExistsAtPath:documentsDirectoryUrl]) {
		NSError *error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectoryUrl withIntermediateDirectories:YES attributes:nil error:&error];
		
		if (error != nil) {
			@throw [NSException exceptionWithName:@"directoryException" reason:@"could not create directory" userInfo:nil];
		}
	}
	
	return documentsDirectoryUrl;
}

@end
