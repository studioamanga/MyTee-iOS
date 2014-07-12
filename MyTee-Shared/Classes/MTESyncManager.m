//
//  MTESyncManager.m
//  mytee
//
//  Created by Vincent Tourraine on 9/4/13.
//  Copyright (c) 2013 Studio AMANgA. All rights reserved.
//

#import "MTESyncManager.h"
#import "MTEMyTeeAPIClient.h"
#import "MTETShirt.h"
#import "MTEWear.h"
#import "MTEWash.h"

NSString *const kMTETShirtsFilterType = @"kMTETShirtsFilterType";
NSString *const kMTETShirtsFilterParameter = @"kMTETShirtsFilterParameter";

@interface MTESyncManager ()

@property (strong, nonatomic) MTEMyTeeAPIClient *client;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (assign, nonatomic, getter = isSyncing) BOOL syncing;
@end


@implementation MTESyncManager

+ (MTESyncManager *)syncManagerWithClient:(MTEMyTeeAPIClient *)client
                                  context:(NSManagedObjectContext *)context
{
    MTESyncManager *syncManager = [MTESyncManager new];
    syncManager.client  = client;
    syncManager.context = context;
    return syncManager;
}

- (void)syncSuccess:(void (^)(UIBackgroundFetchResult result))success
            failure:(void (^)(NSError *error))failure
{
    if (self.isSyncing) {
        if (failure) {
            failure(nil);
        }
        return;
    }
    
    self.syncing = YES;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MTETShirt"];
    
    NSURLRequest *request = [self.client requestForFetchRequest:fetchRequest
                                                    withContext:self.context];
    AFHTTPRequestOperation *operation = [self.client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL newData = NO;
        
        for (NSDictionary *tshirtObject in (NSArray *)responseObject) {
            MTETShirt *tshirt;
            NSString *identifier = tshirtObject[@"identifier"];
            
            NSFetchRequest *tshirtFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MTETShirt"];
            tshirtFetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
            tshirt = [[self.context executeFetchRequest:tshirtFetchRequest error:nil] lastObject];
            
            if (!tshirt) {
                tshirt = [NSEntityDescription insertNewObjectForEntityForName:@"MTETShirt" inManagedObjectContext:self.context];
                newData = YES;
            }
            
            NSDictionary *attributes = [self.client attributesForRepresentation:tshirtObject
                                                                       ofEntity:tshirtFetchRequest.entity
                                                                   fromResponse:operation.response];
            
            for (NSDictionary *wearObject in tshirtObject[@"wear"]) {
                NSString *wearIdentifier = wearObject[@"identifier"];
                
                NSFetchRequest *wearFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MTEWear"];
                wearFetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", wearIdentifier];
                NSUInteger numberOfExistingWear = [self.context countForFetchRequest:wearFetchRequest error:nil];
                
                if (numberOfExistingWear == 0) {
                    MTEWear *wear = [NSEntityDescription insertNewObjectForEntityForName:@"MTEWear" inManagedObjectContext:self.context];
                    wear.tshirt = tshirt;
                    wear.identifier = wearIdentifier;
                    
                    NSDictionary *wearAttributes = [self.client attributesForRepresentation:wearObject ofEntity:wear.entity fromResponse:operation.response];
                    wear.date   = wearAttributes[@"date"];
                    
                    newData = YES;
                }
            }
            
            for (NSDictionary *washObject in tshirtObject[@"wash"]) {
                NSString *washIdentifier = washObject[@"identifier"];
                
                NSFetchRequest *washFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MTEWash"];
                washFetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", washIdentifier];
                NSUInteger numberOfExistingWash = [self.context countForFetchRequest:washFetchRequest error:nil];
                
                if (numberOfExistingWash == 0) {
                    MTEWash *wash = [NSEntityDescription insertNewObjectForEntityForName:@"MTEWash" inManagedObjectContext:self.context];
                    wash.tshirt = tshirt;
                    wash.identifier = washIdentifier;
                    
                    NSDictionary *washAttributes = [self.client attributesForRepresentation:washObject ofEntity:wash.entity fromResponse:operation.response];
                    wash.date   = washAttributes[@"date"];
                    
                    newData = YES;
                }
            }
            
            [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (![obj isKindOfClass:[NSNull class]]) {
                    [tshirt setValue:obj forKey:key];
                }
            }];
            
            [tshirt updateNumberOfWearsSinceLastWash];
        }
        
        [self.context save:nil];
        
        self.syncing = NO;
        if (success)
            success(newData ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.syncing = NO;
        if (failure)
            failure(error);
    }];
    
    [self.client enqueueHTTPRequestOperation:operation];
}

@end
