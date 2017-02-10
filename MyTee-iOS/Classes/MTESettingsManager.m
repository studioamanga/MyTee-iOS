//
//  MTESettingsManager.m
//  mytee
//
//  Created by Vincent Tourraine on 2/19/12.
//  Copyright (c) 2012-2017 Studio AMANgA. All rights reserved.
//

@import UIKit;
@import UserNotifications;

#import "MTESettingsManager.h"

#define MTE_USER_DEFAULTS_REMINDERS_ACTIVE @"kMTEUserDefaultsRemindersActive"

#define MTE_REMINDER_HOUR 8

@implementation MTESettingsManager

+ (BOOL)isRemindersActive {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:MTE_USER_DEFAULTS_REMINDERS_ACTIVE];
}

+ (void)setRemindersActive:(BOOL)active {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:active forKey:MTE_USER_DEFAULTS_REMINDERS_ACTIVE];
    [userDefaults synchronize];

    // Scheduling notification
    UIApplication *application = [UIApplication sharedApplication];
    [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];

    if (active) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.hour = [self remindersHour];
        UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:YES];

        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = NSLocalizedString(@"Time to Dress", nil);
        content.body = NSLocalizedString(@"Let’s choose something awesome!", nil);
        content.badge = @1;

        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"textNotification" content:content trigger:trigger];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@", error);
            }
        }];
    }
    else {
        application.applicationIconBadgeNumber = 0;
    }
}

+ (NSUInteger)remindersHour {
    return MTE_REMINDER_HOUR;
}

@end
