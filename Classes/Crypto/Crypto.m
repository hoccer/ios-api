//
//  Crypto.m
//  Hoccer
//
//  Created by Robert Palmer on 17.06.11.
//  Copyright 2011 Hoccer GmbH. All rights reserved.
//

#import "NSData+CommonCrypto.h"

#import "Crypto.h"
#import "NSString+StringWithData.h"
#import "NSData_Base64Extensions.h"

@implementation NoCryptor

- (NSData *)encrypt:(NSData *)data {
    return data;
}

- (NSData *)decrypt:(NSData *)data {
    return data;
}

- (NSString *)encryptString: (NSString *)string {
    return string;
}

- (NSString *)decryptString: (NSString *)string {
    return string;
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

- (NSString *)encryptString: (NSString *)string {
    NSData *data      = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encripted = [self encrypt:data];
    
    return [encripted asBase64EncodedString];
}

- (NSString *)decryptString: (NSString *)string {
    NSData *data      = [NSData dataWithBase64EncodedString:string];
    NSData *decrypted = [self decrypt:data];
    
    return [NSString stringWithData:decrypted usingEncoding:NSUTF8StringEncoding];
}


- (void)dealloc {
    [key release];
    [super dealloc];
}

@end