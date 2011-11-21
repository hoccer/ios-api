//
//  RSA.h
//  Hoccer
//
//  Created by Robert Palmer on 23.06.11.
//  Copyright 2011 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSA : NSObject {
    NSData *publicTag;
    NSData *privateTag;
}


+ (RSA*)sharedInstance;

- (void)encryptWithPublicKey:(uint8_t *)plainBuffer cipherBuffer:(uint8_t *)cipherBuffer;
- (void)generateKeyPairKeys;
- (void)testEncryption;

- (SecKeyRef)getPrivateKeyRef;
- (NSData *)getPublicKeyBits;
- (SecKeyRef)getPublicKeyRef;
- (NSData *)getPrivateKeyBits;

- (void)decryptWithPrivateKey:(uint8_t *)cipherBuffer plainBuffer:(uint8_t *)plainBuffer;
- (void)encryptWithPublicKey:(uint8_t *)plainBuffer cipherBuffer:(uint8_t *)cipherBuffer;

- (NSData *)encryptWithKey:(SecKeyRef)key plainData:(NSData *)plainData;
- (NSData *)decryptWithKey: (SecKeyRef)key cipherData: (NSData *)cipherData;

- (SecKeyRef)getKeyRefWithPersistentKeyRef:(CFTypeRef)persistentRef;
- (CFTypeRef)getPersistentKeyRefWithKeyRef:(SecKeyRef)keyRef;
- (void)removePeerPublicKey:(NSString *)peerName;
- (SecKeyRef)getPeerKeyRef:(NSString *)peerName;

- (NSData *)stripPublicKeyHeader:(NSData *)d_key;
- (BOOL)addPublicKey:(NSString *)key withTag:(NSString *)tag;

- (NSData *)getKeyBitsForPeerRef:(NSString *)peerName;

- (void)getCertificate;

-(void)cleanKeyChain;

- (NSString *)genRandomString:(int)length;

@end
