//
//  MTEAppDelegate.h
//  MyTee-OSX
//
//  Created by Vincent Tourraine on 12/07/14.
//  Copyright (c) 2014 Studio AMANgA. All rights reserved.
//

@import Cocoa;

@interface MTEAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel         *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext       *managedObjectContext;

- (void)showLoginWindow;
- (void)hideLoginWindow;

- (IBAction)startSync:(id)sender;
- (IBAction)saveAction:(id)sender;

@end
