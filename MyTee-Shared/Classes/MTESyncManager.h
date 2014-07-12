//
//  MTESyncManager.h
//  mytee
//
//  Created by Vincent Tourraine on 9/4/13.
//  Copyright (c) 2013 Studio AMANgA. All rights reserved.
//

@import Foundation;

FOUNDATION_EXPORT NSString *const kMTETShirtsFilterType;
FOUNDATION_EXPORT NSString *const kMTETShirtsFilterParameter;

typedef NS_ENUM (NSUInteger, MTETShirtsFilterType)
{
    MTETShirtsFilterAll = 0,
    MTETShirtsFilterWear,
    MTETShirtsFilterWash
};

@class MTEMyTeeAPIClient;

#if ! TARGET_OS_IPHONE
typedef NS_ENUM(NSUInteger, UIBackgroundFetchResult) {
    UIBackgroundFetchResultNewData,
    UIBackgroundFetchResultNoData,
    UIBackgroundFetchResultFailed
};
#endif

@interface MTESyncManager : NSObject

+ (MTESyncManager *)syncManagerWithClient:(MTEMyTeeAPIClient *)client
                                  context:(NSManagedObjectContext *)context;

- (void)syncSuccess:(void (^)(UIBackgroundFetchResult result))success
            failure:(void (^)(NSError *error))failure;

@end
