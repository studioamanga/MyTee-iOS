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

@interface MTESyncManager ()

@property (strong, nonatomic) MTEMyTeeAPIClient *client;
@property (strong, nonatomic) NSManagedObjectContext *context;

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

- (void)sync
{
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
            
            [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (![obj isKindOfClass:[NSNull class]]) {
                    [tshirt setValue:obj forKey:key];
                }
            }];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    
    [self.client enqueueHTTPRequestOperation:operation];
}

@end
