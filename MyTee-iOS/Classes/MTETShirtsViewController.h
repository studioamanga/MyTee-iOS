//
//  MTETShirtsViewController.h
//  mytee
//
//  Created by Vincent Tourraine on 1/31/12.
//  Copyright (c) 2012-2016 Studio AMANgA. All rights reserved.
//

#import "MTESettingsViewController.h"
#import "MTELoginViewController.h"

@class MTETShirtViewController;
@class MTESyncManager;

@interface MTETShirtsViewController : UICollectionViewController
 <MTESettingsViewDelegate, MTELoginViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak)   NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) MTESyncManager         *syncManager;

@property (nonatomic, strong) NSIndexPath              *selectedCellIndexPath;
@property (nonatomic, weak)   IBOutlet UIBarButtonItem *settingsBarButtonItem;

- (void)shouldSyncNow:(id)sender;
- (void)syncStarted:(id)sender;
- (void)syncFinished:(id)sender;
- (void)syncFailed:(id)sender;

- (IBAction)showFilterViewController:(id)sender;
- (IBAction)showSettingsViewController:(id)sender;
- (IBAction)showLoginViewController:(id)sender;

@end
