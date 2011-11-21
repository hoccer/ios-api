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

- (id)init {
    self = [super init];
    if (self) {
        
        collectedKeys = [[NSMutableArray alloc]initWithArray:[[NSUserDefaults standardUserDefaults]arrayForKey:@"keyStore"]];
        
        if (collectedKeys == nil){
            collectedKeys = [[NSMutableArray alloc] initWithCapacity:1];
        }
        
    }
    
    return self;
}


-(BOOL)storeKeyRef:(SecKeyRef)theKey{
    return YES;
}

-(BOOL)storeKey:(NSString *)theKey forClient:(NSDictionary *)client{
    
    NSString *theTag = [NSString stringWithFormat:@"com.hoccer.publickey.store.%@",[client objectForKey:@"id"]];
    
    BOOL safed = [[RSA sharedInstance] addPublicKey:theKey withTag:theTag];
    
    if (safed){
        NSArray *IDs = [collectedKeys valueForKey:@"clientId"];
        NSString *search = [client objectForKey:@"id"];
        NSUInteger index = [IDs indexOfObject:search];
        if (IDs.count >= index){
            NSDictionary *storedClient = [collectedKeys objectAtIndex: index];
            [collectedKeys removeObject:storedClient];
        }
        

        
        NSDictionary *keyDicitonary = [[NSDictionary alloc]initWithObjectsAndKeys:theKey,@"key",[client objectForKey:@"id"], @"clientId", [client objectForKey:@"name"], @"clientName", nil];
        [collectedKeys addObject:keyDicitonary];
        [[NSUserDefaults standardUserDefaults] setObject:collectedKeys forKey:@"keyStore"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return safed;
}

-(SecKeyRef)getKeyForClient:(NSDictionary *)client{
    
    NSString *theName = [NSString stringWithFormat:@"com.hoccer.publickey.store.%@",[client objectForKey:@"id"]];

    SecKeyRef theKey = [[RSA sharedInstance] getPeerKeyRef:theName];
    
    if (theKey != nil){
        
        return theKey;
    }
    else {
        return nil;
    }
}
-(BOOL)checkForKeyChange:(NSDictionary *)client withHash:(NSString *)theHash{
    
    BOOL result = YES;
    NSString *theName = [NSString stringWithFormat:@"com.hoccer.publickey.store.%@",[client objectForKey:@"id"]];

    NSData *storedKey = [[RSA sharedInstance] getKeyBitsForPeerRef:theName];
    
    NSString *keyAsString = [storedKey asBase64EncodedString];
    
    NSString *storedHash = [[[[keyAsString dataUsingEncoding:NSUTF8StringEncoding] SHA256Hash] hexString] substringToIndex:8];
    
    if ([storedHash isEqualToString:theHash]){
        result =  NO;
    }
    NSArray *IDs = [collectedKeys valueForKey:@"clientId"];
    NSString *search = [client objectForKey:@"id"];
    NSUInteger index = [IDs indexOfObject:search];
    if (IDs.count >= index){
        NSDictionary *storedClient = [collectedKeys objectAtIndex: index];
    
        if ( ![[storedClient objectForKey:@"clientName"] isEqualToString:[client objectForKey:@"name"]] || ![storedHash isEqualToString: [client objectForKey:@"pubkey_id"]]){
                result = YES;
        }
    
    }
    
    return result;
}

-(void)deleteKeyForClient:(NSString *)theId{
    
    NSArray *IDs = [collectedKeys valueForKey:@"clientId"];
    NSString *search = theId;
    NSUInteger index = [IDs indexOfObject:search];
    
  if (IDs.count >= index){
      [collectedKeys removeObjectAtIndex:index];
  }
    [[NSUserDefaults standardUserDefaults] setObject:collectedKeys forKey:@"keyStore"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *theName = [NSString stringWithFormat:@"com.hoccer.publickey.store.%@",theId];
    [[RSA sharedInstance]removePeerPublicKey:theName];
}

- (void)dealloc {
    [collectedKeys release];
    [super dealloc];
}


@end
