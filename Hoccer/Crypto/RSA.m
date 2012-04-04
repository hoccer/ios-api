
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
const uint32_t PADDING = kSecPaddingPKCS1;

static const uint8_t publicKeyIdentifier[]  = "com.hoccer.client.publickey";
static const uint8_t privateKeyIdentifier[] = "com.hoccer.client.privatekey";

SecKeyRef publicKey;
SecKeyRef privateKey; 

static RSA *instance;


+ (RSA*)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[RSA alloc] init];
        if ([instance getPrivateKeyRef] == nil || [instance getPublicKeyRef] == nil) {
            NSLog(@"There are no keys! PANIC!");
            [instance generateKeyPairKeys];
        }
    }); 
    //[instance getCertificate];
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


- (NSString *)genRandomString:(int)length {
    
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"autoPassword"]){
        NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!§$%&/()=?";

        NSMutableString *randomString = [NSMutableString stringWithCapacity: length];
    
        for (int i=0; i<length; i++) {
            [randomString appendFormat: @"%c", [letters characterAtIndex: rand()%[letters length]]];
        }
    
    
        [[NSUserDefaults standardUserDefaults] setObject:randomString forKey:@"encryptionKey"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    return randomString;
    }
    else {
        return [[NSUserDefaults standardUserDefaults]stringForKey:@"encryptionKey"];
    }
    
}

- (void)generateKeyPairKeys
{
    NSLog(@"Generating Keys");
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
    }else {
        NSLog(@"New key");
    }
    
    [privateKeyAttr release];
    [publicKeyAttr release];
    [keyPairAttr release];
}

- (void)testEncryption {
    NSString *plainText = @"This is just a string";
    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *cipher = [self encryptWithKey:[self getPublicKeyRef] plainData:plainData];

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
                           PADDING, 
                           (const uint8_t *)[plainData bytes], 
                           dataBufferSize,
                           cipherBuffer,
                           &cipherBufferSize);
    
    if (status != noErr) {
        NSLog(@"Error encypring, OSStatus: %d", (NSInteger)status);
    }
        
    cipher = [NSData dataWithBytes:(const void *)cipherBuffer length:(NSUInteger)cipherBufferSize];
    
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
                           PADDING,
                           (const uint8_t *)[cipherData bytes],
                           cipherBufferSize,
                           plainBuffer, 
                           &plainBufferSize);
    
    if (status != noErr) {
        NSLog(@"Error decrypting, OSStatus = %d", (NSInteger)status);
        NSNotification *notification = [NSNotification notificationWithName:@"encryptionError" object:self];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
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
		
        if(resultCode != noErr)
        {
            publicKeyReference = NULL;
        }
		
        [queryPublicKey release];
        publicKey = publicKeyReference;
    } 
	

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
    NSLog(@"getCertificate: result code: %d", (int)resultCode);
	
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
		
        if(resultCode != noErr)
        {
            privateKeyReference = NULL;
        }
		
        [queryPrivateKey release];
        privateKey = privateKeyReference;
    }
    

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
	
	NSMutableDictionary * queryPrivateKey = [[NSMutableDictionary alloc] init];
    
	[queryPrivateKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
	[queryPrivateKey setObject:privateTag forKey:(id)kSecAttrApplicationTag];
	[queryPrivateKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
	[queryPrivateKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnData];
    
	sanityCheck = SecItemCopyMatching((CFDictionaryRef)queryPrivateKey, (CFTypeRef *)&privateKeyBits);
    
	if (sanityCheck != noErr)
	{
		privateKeyBits = nil;
	}
    
	[queryPrivateKey release];
	
	return privateKeyBits;
}

- (NSData *)stripPublicKeyHeader:(NSData *)d_key
{
    // Skip ASN.1 public key header
    if (d_key == nil) return(nil);
    
    unsigned int len = [d_key length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx    = 0;
    
    if (c_key[idx++] != 0x30) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return(nil);
    
    idx += 15;
    
    if (c_key[idx++] != 0x03) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    if (c_key[idx++] != '\0') return(nil);
    
    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

- (BOOL)addPublicKey:(NSString *)key withTag:(NSString *)tag
{
    NSString *s_key = key;
        // This will be base64 encoded, decode it.
    NSData *d_key = [NSData dataWithBase64EncodedString:s_key];
    //d_key = [self stripPublicKeyHeader:d_key];
    if (d_key == nil) return(FALSE);
    
    NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(id) kSecClassKey forKey:(id)kSecClass];
    [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [publicKey setObject:d_tag forKey:(id)kSecAttrApplicationTag];
    SecItemDelete((CFDictionaryRef)publicKey);
    
    CFTypeRef persistKey = nil;
    
    // Add persistent version of the key to system keychain
    [publicKey setObject:d_key forKey:(id)kSecValueData];
    [publicKey setObject:(id) kSecAttrKeyClassPublic forKey:(id)kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnPersistentRef];
    
    OSStatus secStatus = SecItemAdd((CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil) CFRelease(persistKey);
    
    if ((secStatus != noErr) && (secStatus != errSecDuplicateItem)) {
        [publicKey release];
        [d_key release];
        return(FALSE);
    }
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    
    [publicKey removeObjectForKey:(id)kSecValueData];
    [publicKey removeObjectForKey:(id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef
     ];
    [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    SecItemCopyMatching((CFDictionaryRef)publicKey,(CFTypeRef *)&keyRef);
    
    [publicKey release];
    
    if (keyRef == nil) return(FALSE);
    
    
    return(TRUE);
}



- (void)removePeerPublicKey:(NSString *)peerName {
	
	NSData * peerTag = [NSData dataWithBytes:[peerName UTF8String] length:[peerName length]];
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(id) kSecClassKey forKey:(id)kSecClass];
    [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [publicKey setObject:peerTag forKey:(id)kSecAttrApplicationTag];
     SecItemDelete((CFDictionaryRef)publicKey);

	[publicKey release];
}

- (void)cleanKeyChain {
    NSLog(@"Cleaning keychain");
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(id) kSecClassKey forKey:(id)kSecClass];
    [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    SecItemDelete((CFDictionaryRef)publicKey);
    [publicKey release];
    
    [self generateKeyPairKeys];
    

}

- (SecKeyRef)getKeyRefWithPersistentKeyRef:(CFTypeRef)persistentRef {
	SecKeyRef keyRef = NULL;
	
	
	NSMutableDictionary * queryKey = [[NSMutableDictionary alloc] init];
	
	// Set the SecKeyRef query dictionary.
	[queryKey setObject:(id)persistentRef forKey:(id)kSecValuePersistentRef];
	[queryKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
	
	// Get the persistent key reference.
	SecItemCopyMatching((CFDictionaryRef)queryKey, (CFTypeRef *)&keyRef);
    
    
    [queryKey release];

    return keyRef;
    
	
}

- (CFTypeRef)getPersistentKeyRefWithKeyRef:(SecKeyRef)keyRef {
	CFTypeRef persistentRef = NULL;
	
	
	NSMutableDictionary * queryKey = [[NSMutableDictionary alloc] init];
	
	// Set the PersistentKeyRef key query dictionary.
	[queryKey setObject:(id)keyRef forKey:(id)kSecValueRef];
	[queryKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnPersistentRef];
	
	// Get the persistent key reference.
	 SecItemCopyMatching((CFDictionaryRef)queryKey, (CFTypeRef *)&persistentRef);
	[queryKey release];
	
	return persistentRef;
}

- (SecKeyRef)getPeerKeyRef:(NSString *)peerName {
    SecKeyRef persistentRef = NULL;
	
	
    NSData *d_tag = [NSData dataWithBytes:[peerName UTF8String] length:[peerName length]];
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(id) kSecClassKey forKey:(id)kSecClass];
    [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [publicKey setObject:d_tag forKey:(id)kSecAttrApplicationTag];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
    [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];    
    [publicKey setObject:(id) kSecAttrKeyClassPublic forKey:(id)kSecAttrKeyClass];
    SecItemCopyMatching((CFDictionaryRef)publicKey,(CFTypeRef *)&persistentRef);
    
	[publicKey release];
    
    return persistentRef;

}

- (NSData *)getKeyBitsForPeerRef:(NSString *)peerName {
	OSStatus sanityCheck = noErr;
	NSData * publicKeyBits = nil;
	
    NSData *d_tag = [NSData dataWithBytes:[peerName UTF8String] length:[peerName length]];

    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(id) kSecClassKey forKey:(id)kSecClass];
    [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [publicKey setObject:d_tag forKey:(id)kSecAttrApplicationTag];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnData];
    
	sanityCheck = SecItemCopyMatching((CFDictionaryRef)publicKey, (CFTypeRef *)&publicKeyBits);
    
	if (sanityCheck != noErr)
	{
		publicKeyBits = nil;
	}
    
	[publicKey release];
    	
	return publicKeyBits;
}


@end
