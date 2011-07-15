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
#import "NSData+CommonCrypto.h"
#import "NSString+StringWithData.h"

@implementation PublicKeyManager

@synthesize collectedKeys;


-(BOOL)storeKeyRef:(SecKeyRef)theKey{
    return YES;
}

-(BOOL)storeKey:(NSString *)theKey forClient:(NSString *)theId{
    
    //SecKeyRef clientPubKey = [[RSA sharedInstance] addPeerPublicKey:[NSString stringWithFormat:@"com.hoccer.pubkeytest.%@",theId] keyBits:[NSData dataWithBase64EncodedString:theKey]];
    
    NSString *theName = [NSString stringWithFormat:@"com.hoccer.pubkeytest.%@",theId];
    
    BOOL safed = [[RSA sharedInstance] addPublicKey:theKey withTag:theName];
    
    if (safed){
        return YES;
    }
    
    return NO;
}

-(SecKeyRef)getKeyForClient:(NSString *)theId{
    
    NSString *theName = [NSString stringWithFormat:@"com.hoccer.pubkeytest.%@",theId];

    NSLog(@"The Key: %@", theName);
    SecKeyRef theKey = [[RSA sharedInstance] getPeerKeyRef:theName];
    
    if (theKey != nil){
        
        return theKey;
    }
    else {
        return nil;
    }
}
-(BOOL)checkForKeyChange:(NSString *)clientId withHash:(NSString *)theHash{
    
    NSString *theName = [NSString stringWithFormat:@"com.hoccer.pubkeytest.%@",clientId];

    NSData *storedKey = [[RSA sharedInstance] getKeyBitsForPeerRef:theName];
    
    NSString *keyAsString = [storedKey asBase64EncodedString];
            
    if ([[[[[keyAsString dataUsingEncoding:NSUTF8StringEncoding] SHA256Hash] hexString] substringToIndex:8] isEqualToString:theHash]){
        return NO;
    }
    else  {
        return YES;
    }
}

-(void)deleteKeyForClient:(NSString *)theId{
    NSString *theName = [NSString stringWithFormat:@"com.hoccer.pubkeytest.%@",theId];
    [[RSA sharedInstance]removePeerPublicKey:theName];
}



@end
