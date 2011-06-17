//
//  Crypto.h
//  Hoccer
//
//  Created by Robert Palmer on 17.06.11.
//  Copyright 2011 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Cryptor <NSObject>
- (NSData *)encrypt: (NSData *)data;
- (NSData *)decrypt: (NSData *)data;
- (NSString *)encryptString: (NSString *)string;
- (NSString *)decryptString: (NSString *)string;
@end

@interface NoCryptor : NSObject <Cryptor> {
@private
    
}
@end

@interface AESCryptor: NSObject <Cryptor> {
@private
    NSString *key;
    
}

- (id)initWithKey: (NSString *)key;

@end