//
//  MTEAuthenticationManager.h
//  mytee
//
//  Created by Terenn on 1/20/13.
//  Copyright (c) 2013-2017 Studio AMANgA. All rights reserved.
//

@import Foundation;

@interface MTEAuthenticationManager : NSObject

+ (void)storeEmail:(NSString *)email password:(NSString *)password;
+ (NSString *)emailFromKeychain;
+ (NSString *)passwordFromKeychain;
+ (void)resetKeychain;

@end
