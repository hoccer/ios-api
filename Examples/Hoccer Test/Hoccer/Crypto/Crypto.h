//
//  Crypto.h
//  Hoccer
//
//  Created by Robert Palmer on 17.06.11.
//  Copyright 2011 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCLinccer.h"
//static NSData* randomSalt();


@protocol Cryptor <NSObject>
- (NSData *)encrypt: (NSData *)data;
- (NSData *)decrypt: (NSData *)data;
- (NSString *)encryptString: (NSString *)string;
- (NSString *)decryptString: (NSString *)string;
- (void)appendInfoToDictionary: (NSMutableDictionary *)dictionary;

@end

@interface NoCryptor : NSObject <Cryptor> 
@end

@class HCLinccer;
@interface AESCryptor: NSObject <Cryptor,HCLinccerDelegate> {
@private
    NSString *key;
    NSData *salt;
}


- (id)initWithKey:(NSString *)key;
- (id)initWithKey:(NSString *)key salt: (NSData *)salt;
- (id)initWithRandomKey;
- (id)initWithRandomKeyWithSalt:(NSData *)theSalt;
- (NSDictionary *)getEncryptedRandomStringForClient;

@end