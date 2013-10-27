//
//  MTETShirtsViewController.h
//  mytee
//
//  Created by Vincent Tourraine on 1/31/12.
//  Copyright (c) 2012 Studio AMANgA. All rights reserved.
//

#import "MTESettingsViewController.h"
#import "MTELoginViewController.h"
#import "MTETShirtsFilterViewController.h"

@class MTETShirtViewController;
@class MTESyncManager;

@interface MTETShirtsViewController : UICollectionViewController
 <MTESettingsViewDelegate, MTELoginViewDelegate, MTETShirtsFilterViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) MTESyncManager *syncManager;

@property (strong, nonatomic) MTETShirtViewController *detailViewController;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsBarButtonItem;

- (void)shouldSyncNow:(id)sender;
- (void)syncStarted:(id)sender;
- (void)syncFinished:(id)sender;
- (void)syncFailed:(id)sender;

- (IBAction)showFilterViewController:(id)sender;
- (IBAction)showSettingsViewController:(id)sender;

@end
