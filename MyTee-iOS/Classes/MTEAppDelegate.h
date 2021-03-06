//
//  MTEAppDelegate.h
//  mytee
//
//  Created by Vincent Tourraine on 1/28/12.
//  Copyright (c) 2012-2017 Studio AMANgA. All rights reserved.
//

@import UIKit;

@interface MTEAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)resetManagedObjectContext;

@end
