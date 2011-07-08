//
//  PublicKeyManager.m
//  Hoccer
//
//  Created by Philip Brechler on 05.07.11.
//  Copyright 2011 Hoccer GmbH. All rights reserved.
//

#import "PublicKeyManager.h"
#import "RSA.h"
#import "NSData_Base64Extensions.h"
@implementation PublicKeyManager

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(BOOL)storeKeyRef:(SecKeyRef)theKey{
    return YES;
}

-(BOOL)storeKey:(NSString *)theKey forClient:(NSString *)theId{
    
    //SecKeyRef clientPubKey = [[RSA sharedInstance] addPeerPublicKey:[NSString stringWithFormat:@"com.hoccer.pubkeytest.%@",theId] keyBits:[NSData dataWithBase64EncodedString:theKey]];
    
    BOOL safed = [[RSA sharedInstance] addPublicKey:theKey withTag:[NSString stringWithFormat:@"com.hoccer.pubkeytest.%@",theId]];
    
    if (safed){
        return YES;
    }
    
    return NO;
}

-(SecKeyRef)getKeyForClient:(NSString *)theId{
    
    NSString *theName = [NSString stringWithFormat:@"com.hoccer.pubkeytest.%@",theId];

    SecKeyRef theKey = [[RSA sharedInstance] getPeerKeyRef:theName];
    
    if (theKey != nil){

        return theKey;
    }
    else {
        return nil;
    }
}
-(BOOL)checkForKeyChange:(SecKeyRef)theKey{
    
    return NO;
}

-(void)deleteKeyForClient:(NSString *)theId{
    NSString *theName = [NSString stringWithFormat:@"com.hoccer.pubkeytest.%@",theId];
    [[RSA sharedInstance]removePeerPublicKey:theName];
}



@end
