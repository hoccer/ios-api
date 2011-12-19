//
//  NSFileHandler+FileHelper.h
//  Hoccer
//
//  Created by Robert Palmer on 09.12.10.
//  Copyright 2010 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileManager (FileHelper)

- (NSString *)uniqueFilenameForFilename: (NSString *)theFilename inDirectory: (NSString *)directory;
- (NSString *)contentDirectory;

@end
