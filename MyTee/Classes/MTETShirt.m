//
//  MTETShirt.m
//  mytee
//
//  Created by Vincent Tourraine on 1/31/12.
//  Copyright (c) 2012 Studio AMANgA. All rights reserved.
//

#import "MTETShirt.h"

#import "MTEWear.h"
#import "MTEWash.h"

@implementation MTETShirt

@dynamic identifier;
@dynamic name;
@dynamic size;
@dynamic color;
@dynamic condition;
@dynamic location;
@dynamic rating;
@dynamic tags;
@dynamic note;
@dynamic image_url;
@dynamic numberOfDaysSinceLastWear;
@dynamic numberOfWearsSinceLastWash;

@dynamic store, wears, washs;

#pragma mark - Image paths

+ (NSString *)pathToLocalImageDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)pathToLocalImageWithIdentifier:(NSString*)identifier
{
    NSString *fileName = [NSString stringWithFormat:@"MTE_%@.jpg", identifier];
    return [self.pathToLocalImageDirectory stringByAppendingPathComponent:fileName];
}

+ (NSString *)pathToMiniatureLocalImageWithIdentifier:(NSString*)identifier
{
    NSString *fileName = [NSString stringWithFormat:@"MTE_%@_mini.jpg", identifier];
    return [self.pathToLocalImageDirectory stringByAppendingPathComponent:fileName];
}

#pragma mark - Wear/Wash

- (NSArray *)wearsSortedByDate
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    return [self.wears sortedArrayUsingDescriptors:@[descriptor]];
}

- (MTEWear *)mostRecentWear
{
    return self.wearsSortedByDate.firstObject;
}

- (NSArray *)washsSortedByDate
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    return [self.washs sortedArrayUsingDescriptors:@[descriptor]];
}

- (MTEWash *)mostRecentWash
{
    return self.washsSortedByDate.firstObject;
}

- (NSUInteger)updateNumberOfWearsSinceLastWash
{
    NSDate *mostRecentWashDate = self.mostRecentWash.date;

    if (!mostRecentWashDate) {
        self.numberOfWearsSinceLastWash = @(self.wears.count);
        return self.wears.count;
    }

    NSUInteger numberOfDays = [[[NSSet setWithArray:self.wearsSortedByDate] objectsPassingTest:^BOOL(MTEWear *wear, BOOL *stop) {
        return ([wear.date compare:mostRecentWashDate] == NSOrderedDescending);
    }] count];

    self.numberOfWearsSinceLastWash = @(numberOfDays);

    return numberOfDays;
}

@end
