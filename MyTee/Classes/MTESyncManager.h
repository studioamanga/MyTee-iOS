//
//  MTESyncManager.h
//  mytee
//
//  Created by Vincent Tourraine on 9/4/13.
//  Copyright (c) 2013 Studio AMANgA. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTEMyTeeAPIClient;

@interface MTESyncManager : NSObject

+ (MTESyncManager *)syncManagerWithClient:(MTEMyTeeAPIClient *)client
                                  context:(NSManagedObjectContext *)context;
- (void)sync;

@end
