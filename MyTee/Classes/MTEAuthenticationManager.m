//
//  MTEAuthenticationManager.m
//  mytee
//
//  Created by Terenn on 1/20/13.
//  Copyright (c) 2013 Studio AMANgA. All rights reserved.
//

#import "MTEAuthenticationManager.h"

#import <PDKeychainBindingsController.h>

@interface MTEAuthenticationManager ()

+ (PDKeychainBindingsController *)keychainWrapper;
+ (NSString *)valueFromKeychainWithKey:(NSString *)key;

@end


@implementation MTEAuthenticationManager

+ (PDKeychainBindingsController *)keychainWrapper
{
    return [PDKeychainBindingsController sharedKeychainBindingsController];
}

+ (void)resetKeychain
{
    [self storeEmail:nil password:nil];
}

+ (void)storeEmail:(NSString *)email password:(NSString *)password
{
    PDKeychainBindingsController *keychainWrapper = [self keychainWrapper];

    [keychainWrapper storeString:email forKey:(__bridge NSString *)kSecAttrAccount];
    [keychainWrapper storeString:password forKey:(__bridge NSString*)kSecValueData];
}

+ (NSString *)valueFromKeychainWithKey:(NSString *)key
{
    PDKeychainBindingsController *keychainWrapper = [self keychainWrapper];

    NSString *keychainValue = [keychainWrapper stringForKey:key];
    if ([keychainValue isEqualToString:@""]) {
        return nil;
    }

    return keychainValue;
}

+ (NSString *)emailFromKeychain
{
    return [self valueFromKeychainWithKey:(__bridge NSString*)kSecAttrAccount];
}

+ (NSString *)passwordFromKeychain
{
    return [self valueFromKeychainWithKey:(__bridge NSString*)kSecValueData];
}

@end
