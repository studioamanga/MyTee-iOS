//
//  MTEAppDelegate.m
//  mytee
//
//  Created by Vincent Tourraine on 1/28/12.
//  Copyright (c) 2012-2017 Studio AMANgA. All rights reserved.
//

@import UserNotifications;

#import "MTEAppDelegate.h"

#import <AFNetworkActivityIndicatorManager.h>

#import <Colours.h>

#import "MTETShirtsViewController.h"
#import "MTESettingsViewController.h"
#import "MTENavigationControllerDelegate.h"
#import "MTESyncManager.h"
#import "MTEMyTeeAPIClient.h"

@interface MTEAppDelegate ()

@property (nonatomic, strong) MTESyncManager *syncManager;
@property (nonatomic, strong) MTENavigationControllerDelegate *navigationControllerDelegate;
@property (nonatomic, strong, readonly) NSURL *storeURL;

@end


@implementation MTEAppDelegate

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    AFNetworkActivityIndicatorManager.sharedManager.enabled = YES;

    self.window.tintColor = [UIColor colorWithWhite:0.95 alpha:1];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    // [[UINavigationBar appearance] setBarTintColor:UIColor.coolPurpleColor]; // #8C5DE4
    [[UINavigationBar appearance] setTintColor:self.window.tintColor];

    [application setMinimumBackgroundFetchInterval:60*60*12];

    self.navigationControllerDelegate = [MTENavigationControllerDelegate new];

    UINavigationController *navigationController  = (UINavigationController *)self.window.rootViewController;
    MTETShirtsViewController *tshirtsViewController = (MTETShirtsViewController *)navigationController.topViewController;

    navigationController.delegate = self.navigationControllerDelegate;
    [self.navigationControllerDelegate configureWithNavigationController:navigationController];

    self.syncManager = [MTESyncManager syncManagerWithClient:[MTEMyTeeAPIClient sharedClient] context:self.managedObjectContext];

    tshirtsViewController.managedObjectContext = self.managedObjectContext;
    tshirtsViewController.syncManager = self.syncManager;

    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"%@", error);
        }
    }];

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            // abort();
        }
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self.syncManager syncSuccess:^(UIBackgroundFetchResult result) {
        completionHandler(result);
    } failure:^(NSError *error) {
        if (error) {
            completionHandler(UIBackgroundFetchResultFailed);
        }
        else {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    }];
}

#pragma mark - Core Data

- (NSManagedObjectContext *)managedObjectContext {
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }

    return __managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"mytee" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    return __managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }

    NSError *error = nil;
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"mytee.sqlite"];
    NSDictionary *options = @{NSInferMappingModelAutomaticallyOption: @(YES), NSMigratePersistentStoresAutomaticallyOption: @(YES)};

    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return __persistentStoreCoordinator;
}

- (void)removeObjectsInManagedObjectContextForEntityName:(NSString *)entityName {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:nil];
    for (NSManagedObject *object in objects) {
        [self.managedObjectContext deleteObject:object];
    }
}

- (void)resetManagedObjectContext {
    [self removeObjectsInManagedObjectContextForEntityName:@"MTETShirt"];
    [self removeObjectsInManagedObjectContextForEntityName:@"MTEStore"];
    
    [self.managedObjectContext save:nil];
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
