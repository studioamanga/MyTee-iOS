//
//  MTEAppDelegate.m
//  mytee
//
//  Created by Vincent Tourraine on 1/28/12.
//  Copyright (c) 2012 Studio AMANgA. All rights reserved.
//

#import "MTEAppDelegate.h"

#import <AFNetworkActivityIndicatorManager.h>
#import "MTETShirtsViewController.h"
#import "MTESettingsViewController.h"
#import "MTESyncManager.h"
#import "MTEMyTeeAPIClient.h"

@interface MTEAppDelegate ()

@property (nonatomic, strong) MTESyncManager * syncManager;
@property (strong, nonatomic, readonly) NSURL *storeURL;

@end

@implementation MTEAppDelegate

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;

    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackOpaque];
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"linen-nav-bar"]
//                                       forBarMetrics:UIBarMetricsDefault];
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"linen-nav-bar-landscape"]
//                                       forBarMetrics:UIBarMetricsLandscapePhone];
//    [[UINavigationBar appearance] setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor], UITextAttributeTextShadowColor: [UIColor blackColor]}];
//    [[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil] setBackgroundImage:nil
//                                                                                       forBarMetrics:UIBarMetricsDefault];
//    [[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil] setBackgroundImage:nil
//                                                                                       forBarMetrics:UIBarMetricsLandscapePhone];
    
    //[[UIBarButtonItem appearance] setTintColor:[UIColor darkGrayColor]];
    
    [[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"tabbar"]];
    [[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageNamed:@"selection-tab"]];
    [[UITabBar appearance] setSelectedImageTintColor:[UIColor grayColor]];
    
    
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    MTETShirtsViewController * tshirtsViewController = (MTETShirtsViewController*)navController.topViewController;
        
    tshirtsViewController.managedObjectContext = self.managedObjectContext;
    
    self.syncManager = [MTESyncManager syncManagerWithClient:[MTEMyTeeAPIClient sharedClient]
                                                     context:self.managedObjectContext];
    [self.syncManager sync];
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data

- (NSManagedObjectContext *)managedObjectContext {
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return __managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"mytee" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return __managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
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

- (void)resetManagedObjectContext
{
    __managedObjectContext = nil;
    
    NSURL *storeURL = [self storeURL];
    [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
}

- (NSURL *)storeURL
{
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MyTee.sqlite"];
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
