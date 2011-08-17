//
//  PublicKeyManager.h
//  Hoccer
//
//  Created by Philip Brechler on 05.07.11.
//  Copyright 2011 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PublicKeyManager : NSObject{
    
    NSMutableArray *collectedKeys;

}

@property (retain) NSMutableArray *collectedKeys;

-(BOOL)storeKeyRef:(SecKeyRef)theKey;
-(BOOL)storeKey:(NSString *)theKey forClient:(NSDictionary *)client;
-(SecKeyRef)getKeyForClient:(NSDictionary *)client;
-(void)deleteKeyForClient:(NSString *)theId;
-(BOOL)checkForKeyChange:(NSDictionary *)client withHash:(NSString *)theHash;

@end
