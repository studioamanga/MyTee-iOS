//
//  MTESettingsManager.h
//  mytee
//
//  Created by Vincent Tourraine on 2/19/12.
//  Copyright (c) 2012-2017 Studio AMANgA. All rights reserved.
//

@import Foundation;

@interface MTESettingsManager : NSObject

+ (BOOL)isRemindersActive;
+ (void)setRemindersActive:(BOOL)active;

+ (NSUInteger)remindersHour;

@end
