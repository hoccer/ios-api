//
//  RSA.h
//  Hoccer
//
//  Created by Robert Palmer on 23.06.11.
//  Copyright 2011 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSA : NSObject

+ (RSA*)sharedInstance;

- (void)encryptWithPublicKey:(uint8_t *)plainBuffer cipherBuffer:(uint8_t *)cipherBuffer;
- (void)generateKeyPairKeys;
- (void)testAsymmetricEncryptionAndDecryption;

- (SecKeyRef)getPrivateKeyRef;
- (NSData *)getPublicKeyBits;
- (SecKeyRef)getPublicKeyRef;

- (void)decryptWithPrivateKey:(uint8_t *)cipherBuffer plainBuffer:(uint8_t *)plainBuffer;
- (void)encryptWithPublicKey:(uint8_t *)plainBuffer cipherBuffer:(uint8_t *)cipherBuffer;

@end
