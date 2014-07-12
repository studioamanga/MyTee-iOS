//
//  MTETShirt.h
//  mytee
//
//  Created by Vincent Tourraine on 1/31/12.
//  Copyright (c) 2012 Studio AMANgA. All rights reserved.
//

#define MTE_MINIATURE_IMAGE_SIZE 90
#define MTE_MINIATURE_IMAGE_SIZE_IPAD 142

@class MTEStore;
@class MTEWear;
@class MTEWash;

@interface MTETShirt : NSManagedObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *size;
@property (nonatomic, strong) NSString *color;
@property (nonatomic, strong) NSString *condition;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *rating;
@property (nonatomic, strong) NSString *tags;
@property (nonatomic, strong) NSString *note;
@property (nonatomic, strong) NSString *image_url;
@property (nonatomic, strong) NSNumber *numberOfDaysSinceLastWear;
@property (nonatomic, strong) NSNumber *numberOfWearsSinceLastWash;

@property (nonatomic, strong) MTEStore *store;
@property (nonatomic, strong) NSSet *wears;
@property (nonatomic, strong) NSSet *washs;

+ (NSString*)pathToLocalImageWithIdentifier:(NSString*)identifier;
+ (NSString*)pathToMiniatureLocalImageWithIdentifier:(NSString*)identifier;

- (NSArray*)wearsSortedByDate;
- (MTEWear*)mostRecentWear;
- (NSArray*)washsSortedByDate;
- (MTEWash*)mostRecentWash;

- (NSUInteger)updateNumberOfWearsSinceLastWash;

@end
