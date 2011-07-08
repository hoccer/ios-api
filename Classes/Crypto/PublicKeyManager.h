//
//  PublicKeyManager.h
//  Hoccer
//
//  Created by Philip Brechler on 05.07.11.
//  Copyright 2011 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PublicKeyManager : NSObject {

}


-(BOOL)storeKeyRef:(SecKeyRef)theKey;
-(BOOL)storeKey:(NSString *)theKey forClient:(NSString *)theId;
-(SecKeyRef)getKeyForClient:(NSString *)theId;
-(void)deleteKeyForClient:(NSString *)theId;
-(BOOL)checkForKeyChange:(SecKeyRef)theKey;

@end
