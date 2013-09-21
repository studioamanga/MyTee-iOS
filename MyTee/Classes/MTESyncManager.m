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

- (void)syncSuccess:(void (^)())success
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
        for (NSDictionary *tshirtObject in (NSArray *)responseObject) {
            MTETShirt *tshirt;
            NSString *identifier = tshirtObject[@"identifier"];
            
            NSFetchRequest *tshirtFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MTETShirt"];
            tshirtFetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
            tshirt = [[self.context executeFetchRequest:tshirtFetchRequest error:nil] lastObject];
            
            if (!tshirt) {
                tshirt = [NSEntityDescription insertNewObjectForEntityForName:@"MTETShirt" inManagedObjectContext:self.context];
            }
            
            NSDictionary *attributes = [self.client attributesForRepresentation:tshirtObject
                                                                       ofEntity:tshirtFetchRequest.entity
                                                                   fromResponse:operation.response];
            
            for (NSDictionary *wearObject in tshirtObject[@"wear"]) {
                NSString *wearIdentifier = wearObject[@"identifier"];
                
                NSFetchRequest *wearFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MTEWear"];
                wearFetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", wearIdentifier];
                MTEWear *wear = [[self.context executeFetchRequest:wearFetchRequest error:nil] lastObject];
                
                if (!wear) {
                    wear = [NSEntityDescription insertNewObjectForEntityForName:@"MTEWear" inManagedObjectContext:self.context];
                    wear.tshirt = tshirt;
                    
                    NSDictionary *wearAttributes = [self.client attributesForRepresentation:wearObject ofEntity:wear.entity fromResponse:operation.response];
                    wear.date   = wearAttributes[@"date"];
                }
            }
            
            for (NSDictionary *washObject in tshirtObject[@"wash"]) {
                NSString *washIdentifier = washObject[@"identifier"];
                
                NSFetchRequest *washFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MTEWash"];
                washFetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", washIdentifier];
                MTEWash *wash = [[self.context executeFetchRequest:washFetchRequest error:nil] lastObject];
                
                if (!wash) {
                    wash = [NSEntityDescription insertNewObjectForEntityForName:@"MTEWash" inManagedObjectContext:self.context];
                    wash.tshirt = tshirt;
                    
                    NSDictionary *washAttributes = [self.client attributesForRepresentation:washObject ofEntity:wash.entity fromResponse:operation.response];
                    wash.date   = washAttributes[@"date"];
                }
            }
            
            [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (![obj isKindOfClass:[NSNull class]]) {
                    [tshirt setValue:obj forKey:key];
                }
            }];
            
            [self.context save:nil];
            
            self.syncing = NO;
            if (success)
                success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.syncing = NO;
        if (failure)
            failure(error);
    }];
    
    [self.client enqueueHTTPRequestOperation:operation];
}

@end
