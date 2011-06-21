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
#import "NSString+URLHelper.h"


static NSData* randomSalt() {
    NSMutableData *data = [NSMutableData data];
    
    for (NSInteger i = 0; i < 16 / sizeof(u_int32_t); i++) {
        u_int32_t r = arc4random();
        [data appendBytes:&r length:sizeof(u_int32_t)];
    }
    
    return data;
}

static NSData *notSoRandomSalt() {
    NSMutableData *data = [NSMutableData data];
    
    for (NSInteger i = 1; i < 17; i++) {
        char c = (char)i;
        [data appendBytes:&c length:sizeof(char)];
    }
    
    return data;    
}


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

- (void)appendInfoToDictionary:(NSMutableDictionary *)dictionary {
    // not encryption - nothing to do here
}

@end

@interface AESCryptor ()
- (NSData *)saltedKeyHash;
@end


@implementation AESCryptor
- (id)initWithKey: (NSString *)theKey {
    return [self initWithKey:theKey salt:randomSalt()];
}

- (id)initWithKey:(NSString *)theKey salt: (NSData *)theSalt {
    self = [self init];
    if (self) {
        key  = [theKey retain];        
        salt = [theSalt retain];
    }
    return self;
}

- (NSData *)encrypt:(NSData *)data {
    return [data AES256EncryptedDataUsingKey:[self saltedKeyHash] error:nil];
}

- (NSData *)decrypt:(NSData *)data {
    return [data decryptedAES256DataUsingKey:[self saltedKeyHash] error:nil];
}

- (NSString *)encryptString: (NSString *)string {
    NSData *data      = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encripted = [self encrypt:data];
    
    NSLog(@"encrypted %@ to %@", string, encripted);
    NSLog(@"base64 %@", [encripted asBase64EncodedString]);
    
    return [encripted asBase64EncodedString];
}

- (NSString *)decryptString: (NSString *)string {
    NSData *data      = [NSData dataWithBase64EncodedString:string];
    NSData *decrypted = [self decrypt:data];
    
    return [NSString stringWithData:decrypted usingEncoding:NSUTF8StringEncoding];
}

- (void)appendInfoToDictionary: (NSMutableDictionary *)dictionary {
    [dictionary setObject:@"AES" forKey:@"encryption"];
    [dictionary setObject:[NSNumber numberWithInt:128] forKey:@"keysize"];
    [dictionary setObject:[salt asBase64EncodedString] forKey:@"salt"];
}


#pragma mark -
#pragma mark Private Methods
- (NSData *)saltedKeyHash {
    NSMutableData *saltedKey = [[key dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    [saltedKey appendData:salt];
    
    NSLog(@"salt %@, salted key %@",salt, saltedKey);
    NSLog(@"salted key sha %@", [saltedKey SHA1Hash]);
    
    return [[saltedKey SHA1Hash] subdataWithRange:NSMakeRange(0, 16)];
}


- (void)dealloc {
    [key release];
    [salt release];
    
    [super dealloc];
}

@end