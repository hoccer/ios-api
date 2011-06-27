//
//  RSA.m
//  Hoccer
//
//  Created by Robert Palmer on 23.06.11.
//  Copyright 2011 Hoccer GmbH. All rights reserved.
//

#import "RSA.h"

@implementation RSA

const size_t BUFFER_SIZE = 64;
const size_t CIPHER_BUFFER_SIZE = 1024;
const uint32_t PADDING = kSecPaddingNone;

static const UInt8 publicKeyIdentifier[] = "com.hoc.publickey\0";
static const UInt8 privateKeyIdentifier[] = "com.hoc.sample.privatekey\0";

SecKeyRef publicKey;
SecKeyRef privateKey; 

static RSA *instance;


+ (RSA*)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[RSA alloc] init];
        if ([instance getPrivateKeyRef] == nil) {
            NSLog(@"generating key");
            [instance generateKeyPairKeys];
        }
    }); 
    
    return instance;
}



- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (void)generateKeyPairKeys
{
    OSStatus status = noErr;	
    NSMutableDictionary *privateKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *publicKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *keyPairAttr = [[NSMutableDictionary alloc] init];
	
    NSData * publicTag = [NSData dataWithBytes:publicKeyIdentifier
										length:strlen((const char *)publicKeyIdentifier)];
	
    NSData * privateTag = [NSData dataWithBytes:privateKeyIdentifier
										 length:strlen((const char *)privateKeyIdentifier)];
    publicKey = NULL;
    privateKey = NULL;
	
    [keyPairAttr setObject:(id)kSecAttrKeyTypeRSA
					forKey:(id)kSecAttrKeyType];
	
    [keyPairAttr setObject:[NSNumber numberWithInt:1024]
					forKey:(id)kSecAttrKeySizeInBits];
    
    [privateKeyAttr setObject:[NSNumber numberWithBool:YES]
					   forKey:(id)kSecAttrIsPermanent];
	
    [privateKeyAttr setObject:privateTag
					   forKey:(id)kSecAttrApplicationTag];
	
    [publicKeyAttr setObject:[NSNumber numberWithBool:YES]
					  forKey:(id)kSecAttrIsPermanent];
	
    [publicKeyAttr setObject:publicTag
					  forKey:(id)kSecAttrApplicationTag];
    
    [keyPairAttr setObject:privateKeyAttr	 
					forKey:(id)kSecPrivateKeyAttrs];
	
    [keyPairAttr setObject:publicKeyAttr
					forKey:(id)kSecPublicKeyAttrs];
	
    status = SecKeyGeneratePair((CFDictionaryRef)keyPairAttr,
								&publicKey, &privateKey);
    
    
        
}

- (void)testAsymmetricEncryptionAndDecryption {
	
    uint8_t *plainBuffer;
    uint8_t *cipherBuffer;
    uint8_t *decryptedBuffer;
	
    const char inputString[] = "this is a test.  this is only a test.  please remain calm.";
    int len = strlen(inputString);
    // TODO: this is a hack since i know inputString length will be less than BUFFER_SIZE
    if (len > BUFFER_SIZE) len = BUFFER_SIZE-1;
	
    plainBuffer = (uint8_t *)calloc(BUFFER_SIZE, sizeof(uint8_t));
    cipherBuffer = (uint8_t *)calloc(CIPHER_BUFFER_SIZE, sizeof(uint8_t));
    decryptedBuffer = (uint8_t *)calloc(BUFFER_SIZE, sizeof(uint8_t));
	
    strncpy( (char *)plainBuffer, inputString, len);
	
    NSLog(@"init() plainBuffer: %s", plainBuffer);
    //NSLog(@"init(): sizeof(plainBuffer): %d", sizeof(plainBuffer));
    [self encryptWithPublicKey:(UInt8 *)plainBuffer cipherBuffer:cipherBuffer];
    NSLog(@"encrypted data: %s", cipherBuffer);
    //NSLog(@"init(): sizeof(cipherBuffer): %d", sizeof(cipherBuffer));
    [self decryptWithPrivateKey:cipherBuffer plainBuffer:decryptedBuffer];
    NSLog(@"decrypted data: %s", decryptedBuffer);
    //NSLog(@"init(): sizeof(decryptedBuffer): %d", sizeof(decryptedBuffer));
    NSLog(@"====== /second test =======================================");
	
    NSLog(@"public bits und so %@", [self getPublicKeyBits]);
    
    free(plainBuffer);
    free(cipherBuffer);
    free(decryptedBuffer);
}

- (void)encryptWithPublicKey:(uint8_t *)plainBuffer cipherBuffer:(uint8_t *)cipherBuffer
{
    NSLog(@"== encryptWithPublicKey()");
	
    OSStatus status = noErr;	
	
    size_t plainBufferSize = strlen((char *)plainBuffer);
    size_t cipherBufferSize = CIPHER_BUFFER_SIZE;
	SecKeyRef key=[self getPublicKeyRef];
    NSLog(@"SecKeyGetBlockSize() public = %d", (int)SecKeyGetBlockSize(key));
    
    
    
    //  Error handling
    // Encrypt using the public.
    status = SecKeyEncrypt([self getPublicKeyRef],
                           PADDING,
                           plainBuffer,
                           plainBufferSize,
                           &cipherBuffer[0],
                           &cipherBufferSize
                           );
    NSLog(@"encryption result code: %d (size: %d)", (int)status, (int)cipherBufferSize);
    NSLog(@"encrypted text: %s", cipherBuffer);
}

- (void)decryptWithPrivateKey:(uint8_t *)cipherBuffer plainBuffer:(uint8_t *)plainBuffer
{
    OSStatus status = noErr;
	
    size_t cipherBufferSize = strlen((char *)cipherBuffer);
	
    NSLog(@"decryptWithPrivateKey: length of buffer: %d", (int)BUFFER_SIZE);
    NSLog(@"decryptWithPrivateKey: length of input: %d", (int)cipherBufferSize);
	
    // DECRYPTION
    size_t plainBufferSize = BUFFER_SIZE;
	
    //  Error handling
    status = SecKeyDecrypt([self getPrivateKeyRef],
                           PADDING,
                           &cipherBuffer[0],
                           cipherBufferSize,
                           &plainBuffer[0],
                           &plainBufferSize
                           );
    NSLog(@"decryption result code: %d (size: %d)", (int)status, (int)plainBufferSize);
    NSLog(@"FINAL decrypted text: %s", plainBuffer);
	
}

- (SecKeyRef)getPublicKeyRef {
    OSStatus resultCode = noErr;
    SecKeyRef publicKeyReference = NULL;
	
    if(publicKey == NULL) {
        NSMutableDictionary * queryPublicKey = [[NSMutableDictionary alloc] init];
		
		NSData *publicTag = [NSData dataWithBytes:publicKeyIdentifier
                                           length:strlen((const char *)publicKeyIdentifier)]; 
		
        // Set the public key query dictionary.
        [queryPublicKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
        [queryPublicKey setObject:publicTag forKey:(id)kSecAttrApplicationTag];
        [queryPublicKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
        [queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
		
		// Get the key.
        resultCode = SecItemCopyMatching((CFDictionaryRef)queryPublicKey, (CFTypeRef *)&publicKeyReference);
        NSLog(@"getPublicKey: result code: %d", (int)resultCode);
		
        if(resultCode != noErr)
        {
            publicKeyReference = NULL;
        }
		
        [queryPublicKey release];
    } else {
        publicKeyReference = publicKey;
    }
	
    return publicKeyReference;
}

- (SecKeyRef)getPrivateKeyRef {
    OSStatus resultCode = noErr;
    SecKeyRef privateKeyReference = NULL;
	
    if(privateKey == NULL) {
        NSMutableDictionary * queryPrivateKey = [[NSMutableDictionary alloc] init];
		NSData *privateTag = [NSData dataWithBytes:privateKeyIdentifier
                                            length:strlen((const char *)privateKeyIdentifier)]; 
        // Set the private key query dictionary.
        [queryPrivateKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
        [queryPrivateKey setObject:privateTag forKey:(id)kSecAttrApplicationTag];
        [queryPrivateKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
        [queryPrivateKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
		
        // Get the key.
        resultCode = SecItemCopyMatching((CFDictionaryRef)queryPrivateKey, (CFTypeRef *)&privateKeyReference);
        NSLog(@"getPrivateKey: result code: %d", (int)resultCode);
		
        if(resultCode != noErr)
        {
            privateKeyReference = NULL;
        }
		
        [queryPrivateKey release];
    } else {
        privateKeyReference = privateKey;
    }
	
    return privateKeyReference;
}

- (NSData *)getPublicKeyBits {
	OSStatus sanityCheck = noErr;
	NSData * publicKeyBits = nil;
	
	NSMutableDictionary * queryPublicKey = [[NSMutableDictionary alloc] init];
    NSData *publicTag = [NSData dataWithBytes:publicKeyIdentifier
                                       length:strlen((const char *)publicKeyIdentifier)]; 

	[queryPublicKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
	[queryPublicKey setObject:publicTag forKey:(id)kSecAttrApplicationTag];
	[queryPublicKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
	[queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnData];
    
	sanityCheck = SecItemCopyMatching((CFDictionaryRef)queryPublicKey, (CFTypeRef *)&publicKeyBits);
    
	if (sanityCheck != noErr)
	{
		publicKeyBits = nil;
	}
    
	[queryPublicKey release];
	
	return publicKeyBits;
}



@end
