//
//  MTEAppDelegate.m
//  mytee
//
//  Created by Vincent Tourraine on 1/28/12.
//  Copyright (c) 2012 Studio AMANgA. All rights reserved.
//

#import "MTEAppDelegate.h"

#import "MTETodayTShirtViewController.h"
#import "MTETShirtsViewController.h"
#import "MTESettingsViewController.h"
#import "MTESyncManager.h"

@implementation MTEAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"linen-nav-bar"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"linen-nav-bar-landscape"] forBarMetrics:UIBarMetricsLandscapePhone];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, [UIColor blackColor], UITextAttributeTextShadowColor, nil]];
    
    [[UIBarButtonItem appearance] setTintColor:[UIColor darkGrayColor]];
    
    [[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"tabbar"]];
    [[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageNamed:@"selection-tab"]];
    [[UITabBar appearance] setSelectedImageTintColor:[UIColor grayColor]];
    
    MTESyncManager * syncManager = [MTESyncManager new];
    
    [syncManager setupSyncManager];
    [syncManager startSync];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) 
    {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navController0 = [splitViewController.viewControllers objectAtIndex:0];
        UINavigationController *navController1 = [splitViewController.viewControllers objectAtIndex:1];
        MTETShirtsViewController * tshirtsViewController = (MTETShirtsViewController*)navController0.topViewController;
        MTETShirtViewController * tshirtViewController = (MTETShirtViewController*)navController1.topViewController;
        splitViewController.delegate = tshirtViewController;
        
        tshirtsViewController.syncManager = syncManager;
    }
    else 
    {
        UITabBarController * tabBarController = (UITabBarController*)self.window.rootViewController;
        UINavigationController * navController0 = [tabBarController.viewControllers objectAtIndex:0];
        MTETodayTShirtViewController * todayViewController = (MTETodayTShirtViewController*)navController0.topViewController;
        UINavigationController * navController1 = [tabBarController.viewControllers objectAtIndex:1];
        MTETShirtsViewController * tshirtsViewController = (MTETShirtsViewController*)navController1.topViewController;
        UINavigationController * navController2 = [tabBarController.viewControllers objectAtIndex:2];
        MTESettingsViewController * settingsViewController = (MTESettingsViewController*)navController2.topViewController;
        
        UILocalNotification * localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        if (localNotif) 
            tabBarController.selectedIndex = [tabBarController.viewControllers indexOfObject:navController1];
        
        tshirtsViewController.syncManager = syncManager;
        settingsViewController.syncManager = syncManager;
        
        todayViewController.managedObjectContext = self.managedObjectContext;
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"mytee" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"mytee.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
