//
//  Crypto.m
//  Hoccer
//
//  Created by Robert Palmer on 17.06.11.
//  Copyright 2011 Hoccer GmbH. All rights reserved.
//

#import "NSData+CommonCrypto.h"

#import "Crypto.h"

@implementation NoCryptor

- (NSData *)encrypt:(NSData *)data {
    return data;
}

- (NSData *)decrypt:(NSData *)data {
    return data;
}

@end


@implementation AESCryptor
- (id)initWithKey: (NSString *)theKey {
    self = [super init];
    if (self != nil) {
        key = [theKey retain];        
    }
    
    return self;
}

- (NSData *)encrypt:(NSData *)data {
    return [data AES256EncryptedDataUsingKey:key error:nil];
}

- (NSData *)decrypt:(NSData *)data {
    return [data decryptedAES256DataUsingKey:key error:nil];
}

- (void)dealloc {
    [key release];
    [super dealloc];
}

@end