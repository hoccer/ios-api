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
#import "NSString+Regexp.h"
#import "NSString+URLHelper.h"
#import "RSA.h"
#import "PublicKeyManager.h"

static NSData* RandomSalt() {
    NSMutableData *data = [NSMutableData data];
    
    for (NSInteger i = 0; i < 32 / sizeof(u_int32_t); i++) {
        u_int32_t r = arc4random();
        [data appendBytes:&r length:sizeof(u_int32_t)];
    }
    
    return data;
}

static NSData *NotSoRandomSalt() {
    NSMutableData *data = [NSMutableData data];
    
    for (NSInteger i = 1; i < 33; i++) {
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
    return [self initWithKey:theKey salt:RandomSalt()];
}

- (id)initWithKey:(NSString *)theKey salt: (NSData *)theSalt {
    self = [self init];
    if (self) {
        key  = [theKey retain];        
        salt = [theSalt retain];
    }
    return self;
}

- (id)initWithRandomKey{

    NSString *theKey = [[RSA sharedInstance] genRandomString:64];
    return [self initWithKey:theKey salt:RandomSalt()];
}

- (id)initWithRandomKeyWithSalt:(NSData *)theSalt{
    NSString *theKey = [[RSA sharedInstance] genRandomString:64];
    return [self initWithKey:theKey salt:theSalt];
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
        
    return [encripted asBase64EncodedString];
}

- (NSString *)decryptString: (NSString *)string {
    NSData *data      = [NSData dataWithBase64EncodedString:string];
    NSData *decrypted = [self decrypt:data];
    
    return [NSString stringWithData:decrypted usingEncoding:NSUTF8StringEncoding];
    [data release];
}

- (void)appendInfoToDictionary: (NSMutableDictionary *)dictionary {
    
    NSDictionary *cryptedPassword = [self getEncryptedRandomStringForClient];
     
    if (cryptedPassword != nil){
        NSDictionary *encryption = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"AES", @"method",
                                    [NSNumber numberWithInt:256], @"keysize",
                                    [salt asBase64EncodedString], @"salt", 
                                    @"SHA256", @"hash", cryptedPassword, @"password", nil];

    
        [dictionary setObject:encryption forKey:@"encryption"];
    }
    else {
        NSNotification *notification = [NSNotification notificationWithName:@"encryptionError" object:self];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
    
}



- (NSDictionary *)getEncryptedRandomStringForClient {
    
    NSArray *selectedClients;
    PublicKeyManager *keyManager = [[PublicKeyManager alloc]init];
    
    if ([[NSUserDefaults standardUserDefaults] arrayForKey:@"selected_clients"] !=nil){
           selectedClients = [[NSUserDefaults standardUserDefaults] arrayForKey:@"selected_clients"];
        
        if (selectedClients.count == 0 ){
            NSLog(@"So wird das nichts!");
            return nil;
        }
        else {
            NSDictionary *toReturn = [[NSMutableDictionary alloc]initWithCapacity:selectedClients.count];
            
            for (NSDictionary *aClient in selectedClients){
                
                NSString *thePass = [[NSUserDefaults standardUserDefaults] stringForKey:@"encryptionKey"];
                NSData *passData = [thePass dataUsingEncoding:NSUTF8StringEncoding];
                SecKeyRef theKeyRef = [keyManager getKeyForClient:[aClient objectForKey:@"id"]];            
                if (theKeyRef != nil){
        
                    NSData *cipher = [[RSA sharedInstance] encryptWithKey:theKeyRef plainData:passData];
                    NSLog(@"Cipher %@",[cipher asBase64EncodedString]);
                    [toReturn setValue:[cipher asBase64EncodedString] forKey:[aClient objectForKey:@"id"]];
                }
            }
            return toReturn;
        }
    }
    return nil;
    [keyManager release];
}


#pragma mark -
#pragma mark Private Methods
- (NSData *)saltedKeyHash {
    NSMutableData *saltedKey = [[[key dataUsingEncoding:NSUTF8StringEncoding] mutableCopy] autorelease];
    [saltedKey appendData:salt];
    return [[saltedKey SHA256Hash] subdataWithRange:NSMakeRange(0, 32)];
}


- (void)dealloc {
    [key release];
    [salt release];
    [super dealloc];
}

@end