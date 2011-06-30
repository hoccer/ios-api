//
//  RSA.m
//  Hoccer
//
//  Created by Robert Palmer on 23.06.11.
//  Copyright 2011 Hoccer GmbH. All rights reserved.
//

#import "RSA.h"
#import "NSData_Base64Extensions.h"

@implementation RSA

const size_t BUFFER_SIZE = 64;
const size_t CIPHER_BUFFER_SIZE = 1024;
const uint32_t PADDING = kSecPaddingNone;

static const uint8_t publicKeyIdentifier[]  = "com.hoccer.sample.publickey";
static const uint8_t privateKeyIdentifier[] = "com.hoccer.sample.privatekey";

SecKeyRef publicKey;
SecKeyRef privateKey; 

static RSA *instance;


+ (RSA*)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[RSA alloc] init];
        if ([instance getPrivateKeyRef] == nil || [instance getPublicKeyRef] == nil) {
            NSLog(@"generating key");
            [instance generateKeyPairKeys];
        }
    }); 
    [instance getCertificate];

    return instance;
}



- (id)init
{
    self = [super init];
    if (self) {
        privateTag = [[NSData alloc] initWithBytes:privateKeyIdentifier length:sizeof(privateKeyIdentifier)];
        publicTag = [[NSData alloc] initWithBytes:publicKeyIdentifier length:sizeof(publicKeyIdentifier)];
    }
    
    return self;
}


- (void)generateKeyPairKeys
{
    OSStatus status = noErr;	
    NSMutableDictionary *privateKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *publicKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *keyPairAttr = [[NSMutableDictionary alloc] init];
	
    publicKey = NULL;
    privateKey = NULL;
	
    [privateKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecAttrIsPermanent];
    [privateKeyAttr setObject:privateTag forKey:(id)kSecAttrApplicationTag];
    
    [publicKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecAttrIsPermanent];
	[publicKeyAttr setObject:publicTag forKey:(id)kSecAttrApplicationTag];
    
    [keyPairAttr setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [keyPairAttr setObject:[NSNumber numberWithInt:1024] forKey:(id)kSecAttrKeySizeInBits];
    
    [keyPairAttr setObject:privateKeyAttr forKey:(id)kSecPrivateKeyAttrs];
	[keyPairAttr setObject:publicKeyAttr forKey:(id)kSecPublicKeyAttrs];
	
    status = SecKeyGeneratePair((CFDictionaryRef)keyPairAttr, &publicKey, &privateKey);
    
    if (status != noErr) {
        NSLog(@"something went wrong %d", (int)status);
    }
    
    [privateKeyAttr release];
    [publicTag release];
    [keyPairAttr release];
}

- (void)testEncryption {
    NSString *plainText = @"Hello world, woooo";
    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *cipher = [self encryptWithKey:[self getPublicKeyRef] plainData:plainData];
    
    NSLog(@"cypher %@", cipher);
    NSData *decryptedData = [self decryptWithKey:[self getPrivateKeyRef] cipherData:cipher];
    NSString *decryptedString = [[[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding] autorelease];
    
    NSLog(@"decrypted %@", decryptedString);
}


- (NSData *)encryptWithKey:(SecKeyRef)key plainData:(NSData *)plainData {
    OSStatus status = noErr;	
    
    size_t cipherBufferSize = 0;
    size_t dataBufferSize    = 0;
    
    NSData *cipher = nil;
    uint8_t *cipherBuffer = nil;
    
    cipherBufferSize = SecKeyGetBlockSize(key);
    dataBufferSize = [plainData length];
    
    cipherBuffer = malloc(cipherBufferSize * sizeof(uint8_t));
    memset((void *)cipherBuffer, 0x0, cipherBufferSize);
        
    status = SecKeyEncrypt( key, 
                           kSecPaddingNone, 
                           (const uint8_t *)[plainData bytes], 
                           dataBufferSize,
                           cipherBuffer,
                           &cipherBufferSize);
    
    if (status != noErr) {
        NSLog(@"Error encypring, OSStatus: %d", (NSInteger)status);
    }
        
    cipher = [NSData dataWithBytes:(const void *)cipherBuffer length:(NSUInteger)cipherBufferSize];
    NSLog(@"encoded %d bytes, data %@", (NSInteger)cipherBufferSize, cipher);
    
    return cipher;
}

- (NSData *)decryptWithKey: (SecKeyRef)key cipherData: (NSData *)cipherData {
    OSStatus status = noErr;
    size_t cipherBufferSize = 0;
    size_t plainBufferSize  = 0;
    
    NSData *plainData       = nil;
    uint8_t * plainBuffer   = NULL;
    
    cipherBufferSize = SecKeyGetBlockSize(key);
    
    plainBufferSize  = [cipherData length]; 
    plainBuffer = malloc(plainBufferSize * sizeof(uint8_t));
    memset((void *)plainBuffer, 0x0, plainBufferSize);
    
    status = SecKeyDecrypt(key, 
                           kSecPaddingNone,
                           (const uint8_t *)[cipherData bytes],
                           cipherBufferSize,
                           plainBuffer, 
                           &plainBufferSize);
    
    if (status != noErr) {
        NSLog(@"Error decrypting, OSStatus = %d", (NSInteger)status);
    }
    
    NSLog(@"decoded %d bytes, status %d", (NSInteger)plainBufferSize, (NSInteger)status);
    plainData = [NSData dataWithBytes:plainBuffer length:plainBufferSize];
    
    if (plainBuffer) { free(plainBuffer); }
    return plainData;
}


- (void)encryptWithPublicKey:(uint8_t *)plainBuffer cipherBuffer:(uint8_t *)cipherBuffer
{	
    OSStatus status = noErr;	
	
    size_t plainBufferSize = strlen((char *)plainBuffer);
    size_t cipherBufferSize = CIPHER_BUFFER_SIZE;
	SecKeyRef key = [self getPublicKeyRef];
    NSLog(@"SecKeyGetBlockSize() public = %d", (int)SecKeyGetBlockSize(key));
    
    
    
    //  Error handling
    // Encrypt using the public.
    status = SecKeyEncrypt(key,
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
        publicKey = publicKeyReference;
    } 
	
    NSLog(@"public key ref %d", (NSInteger)publicTag);

    return publicKey;
}

- (void)getCertificate {
    OSStatus resultCode = noErr;
    SecCertificateRef publicKeyCeritificate = NULL;
	
    NSMutableDictionary * queryPublicKey = [[NSMutableDictionary alloc] init];
    
    // Set the public key query dictionary.
    [queryPublicKey setObject:(id)kSecClassCertificate forKey:(id)kSecClass];
    [queryPublicKey setObject:publicTag forKey:(id)kSecAttrApplicationTag];
    [queryPublicKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
	
	// Get the key.
    resultCode = SecItemCopyMatching((CFDictionaryRef)queryPublicKey, (CFTypeRef *)&publicKeyCeritificate);
    NSLog(@"getPublicKey: result code: %d", (int)resultCode);
	
    if(resultCode != noErr)
    {
        publicKeyCeritificate = NULL;
    }
	
    [queryPublicKey release];    
}


- (SecKeyRef)getPrivateKeyRef {
    OSStatus resultCode = noErr;
    SecKeyRef privateKeyReference = NULL;
	
    if(privateKey == NULL) {
        NSMutableDictionary * queryPrivateKey = [[NSMutableDictionary alloc] init];

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
        privateKey = privateKeyReference;
    }
    
    NSLog(@"private key ref %d", (NSInteger)privateKeyReference);
    return privateKey;
}

- (NSData *)getPublicKeyBits {
	OSStatus sanityCheck = noErr;
	NSData * publicKeyBits = nil;
	
	NSMutableDictionary * queryPublicKey = [[NSMutableDictionary alloc] init];

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

- (NSData *)getPrivateKeyBits {
	OSStatus sanityCheck = noErr;
	NSData * privateKeyBits = nil;
	
	NSMutableDictionary * queryPublicKey = [[NSMutableDictionary alloc] init];
    
	[queryPublicKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
	[queryPublicKey setObject:publicTag forKey:(id)kSecAttrApplicationTag];
	[queryPublicKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
	[queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnData];
    
	sanityCheck = SecItemCopyMatching((CFDictionaryRef)queryPublicKey, (CFTypeRef *)&privateKeyBits);
    
	if (sanityCheck != noErr)
	{
		privateKeyBits = nil;
	}
    
	[queryPublicKey release];
	
	return privateKeyBits;
}

- (void)deleteKeyPair {
    
}




@end
