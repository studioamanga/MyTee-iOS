//
//  MTETShirtsViewController.m
//  mytee
//
//  Created by Vincent Tourraine on 1/31/12.
//  Copyright (c) 2012 Studio AMANgA. All rights reserved.
//

#import "MTETShirtsViewController.h"

#import "MTETShirt.h"
#import "MTEAuthenticationManager.h"
#import "MTEAppDelegate.h"
#import "MTESyncManager.h"

#import "MBProgressHUD.h"
#import "MTEConstView.h"

#import "MTETShirtViewController.h"
#import "MTESettingsViewController.h"
#import "MTELoginViewController.h"

#import <AFNetworking.h>
#import <QuartzCore/QuartzCore.h>

@interface MTETShirtsViewController () <UIPopoverControllerDelegate, NSFetchedResultsControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

- (void)startRefresh:(id)sender;
- (void)configureForFilterType:(MTETShirtsFilterType)filterType;

@end


@implementation MTETShirtsViewController

#pragma mark - View lifecycle

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MTETShirt class])];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    MTETShirtsFilterType filterType = [userDefaults integerForKey:kMTETShirtsFilterType];
    NSSortDescriptor *sortDescriptor;
    NSString *sectionNameKeyPath;
    
    switch (filterType) {
        case MTETShirtsFilterAll:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"color" ascending:YES];
            sectionNameKeyPath = @"color";
            break;
            
        case MTETShirtsFilterWash:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"numberOfWearsSinceLastWash" ascending:NO];
            sectionNameKeyPath = @"numberOfWearsSinceLastWash";
            break;
            
        case MTETShirtsFilterWear:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"color" ascending:YES];
            break;
    }
    
    fetchRequest.sortDescriptors = @[sortDescriptor];
    self.fetchedResultsController = [[NSFetchedResultsController alloc]
                                     initWithFetchRequest:fetchRequest
                                     managedObjectContext:managedObjectContext
                                     sectionNameKeyPath:sectionNameKeyPath
                                     cacheName:nil];
    
    self.fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    BOOL result = [self.fetchedResultsController performFetch:&error];
    if(!result)
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.detailViewController = (MTETShirtViewController*)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor blackColor];
    [refreshControl addTarget:self action:@selector(startRefresh:)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    MTETShirtsFilterType filterType = [userDefaults integerForKey:kMTETShirtsFilterType];
    [self configureForFilterType:filterType];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSString *email = [MTEAuthenticationManager emailFromKeychain];
    if (!email)
        [self performSegueWithIdentifier:@"MTELoginSegue" sender:nil];
}

- (void)configureForFilterType:(MTETShirtsFilterType)filterType
{
    NSString *filterIconName;
    switch (filterType) {
        case MTETShirtsFilterAll:
            self.title     = @"My T-Shirts";
            filterIconName = @"33-cabinet-b";
            break;
            
        case MTETShirtsFilterWash:
            self.title     = @"T-Shirts to Wash";
            filterIconName = @"wash-b";
            break;
            
        case MTETShirtsFilterWear:
            self.title     = @"T-Shirt to Wear";
            filterIconName = @"118-coat-hanger";
            break;
    }
    
    UIBarButtonItem *filterBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:filterIconName]
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(showFilterViewController:)];
    self.navigationItem.leftBarButtonItem = filterBarButtonItem;
}

#pragma mark - Actions

- (void)startRefresh:(id)sender
{
    [self.syncManager syncSuccess:^{
        if ([sender isKindOfClass:[UIRefreshControl class]])
            [(UIRefreshControl *)sender endRefreshing];
    } failure:^(NSError *error) {
        if ([sender isKindOfClass:[UIRefreshControl class]])
            [(UIRefreshControl *)sender endRefreshing];
    }];
}

- (IBAction)showFilterViewController:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"All", @"Wear", @"Wash", nil];
    [actionSheet showFromBarButtonItem:(id)sender animated:YES];
}

- (IBAction)showSettingsViewController:(id)sender
{
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        storyboard = [UIStoryboard storyboardWithName:@"Storyboard_iPhone" bundle:[NSBundle mainBundle]];
    else
        storyboard = self.storyboard;
    
    UINavigationController *settingsNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"MTESettingsNavigationController"];
    settingsNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    MTESettingsViewController *viewController = (MTESettingsViewController*)settingsNavigationController.topViewController;
    viewController.delegate = self;
    [self presentViewController:settingsNavigationController animated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"MTELoginSegue"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        MTELoginViewController *viewController = (MTELoginViewController*)navigationController.topViewController;
        viewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"MTETShirtSegue"]) {
        MTETShirtViewController *viewController = nil;
        if ([segue.destinationViewController isMemberOfClass:[MTETShirtViewController class]]) {
             viewController = segue.destinationViewController;
        }
        else if ([segue.destinationViewController isMemberOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *)segue.destinationViewController;
            viewController = (MTETShirtViewController *)navigationController.topViewController;
        }
        
        NSIndexPath *indexPath = [[self.collectionView indexPathsForSelectedItems] lastObject];
        MTETShirt *tshirt      = [self.fetchedResultsController objectAtIndexPath:indexPath];
        viewController.tshirt = tshirt;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        UIImage *woodTexture = [UIImage imageNamed:(UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) ? @"shelves-portrait" : @"shelves-landscape"];
        UIColor *woodColor = [UIColor colorWithPatternImage:woodTexture];
        self.collectionView.backgroundColor = woodColor;
    }
}

#pragma mark - Collection view data source

- (int)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.sections.count;
}

- (int)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    NSLog(@"%@ (%d objects)", sectionInfo.name, sectionInfo.numberOfObjects);
    return sectionInfo.numberOfObjects;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MTETShirtCellID" forIndexPath:indexPath];
    
    MTETShirt *tshirt = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UIImageView *tshirtImageView = nil;
    if ([[cell.contentView.subviews lastObject] isMemberOfClass:[UIImageView class]])
        tshirtImageView = [cell.contentView.subviews lastObject];
    
    if (!tshirtImageView) {
        tshirtImageView = [[UIImageView alloc] init];
        tshirtImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            CGFloat tshirtSize = cell.bounds.size.width - 2*20;
            tshirtImageView.frame = CGRectMake(10, (cell.bounds.size.height - tshirtSize)/2 + 8, tshirtSize, tshirtSize);
        }
        else {
            CGFloat tshirtSize = cell.bounds.size.width - 2*8;
            tshirtImageView.frame = CGRectMake(8, (cell.bounds.size.height - tshirtSize)/2 + 8, tshirtSize, tshirtSize);
        }
        
        tshirtImageView.layer.borderColor = [[UIColor blackColor] CGColor];
        tshirtImageView.layer.borderWidth = 1;
        tshirtImageView.layer.cornerRadius = 4;
        tshirtImageView.clipsToBounds = YES;
        
        [cell.contentView addSubview:tshirtImageView];
    }
    
    [tshirtImageView setImageWithURL:[NSURL URLWithString:tshirt.image_url]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.detailViewController.navigationController popToRootViewControllerAnimated:YES];
        
        MTETShirt *tshirt = [self.fetchedResultsController objectAtIndexPath:indexPath];
        self.detailViewController.tshirt = tshirt;
    }
}

#pragma mark - Login

- (void)loginViewControllerDidLoggedIn:(MTELoginViewController *)loginViewController
{
    [self.syncManager syncSuccess:nil failure:nil];
}

#pragma mark - Sync

- (void)shouldSyncNow:(id)sender
{
}

- (void)syncStarted:(id)sender
{
}

- (void)syncFinished:(id)sender
{
    [self.collectionView reloadData];
}

- (void)syncFailed:(id)sender
{
    MBProgressHUD *progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:MTE_HUD_IMAGE_ERROR]];
    progressHUD.mode = MBProgressHUDModeCustomView;
    progressHUD.labelText = @"Sync Failed";
    
    [progressHUD hide:YES afterDelay:MTE_HUD_HIDE_DELAY];
}

#pragma mark - Settings view controller delegate

- (void)settingsViewControllerShouldClose:(MTESettingsViewController *)settingsViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)settingsViewControllerShouldSyncNow:(MTESettingsViewController *)settingsViewController
{
}

- (void)settingsViewControllerShouldLogOut:(MTESettingsViewController *)settingsViewController
{   
    [MTEAuthenticationManager resetKeychain];
    [((MTEAppDelegate *)[UIApplication sharedApplication].delegate) resetManagedObjectContext];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Popover controller

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    MTETShirtsFilterType filterType;
    switch (buttonIndex) {
        case 0:
            filterType = MTETShirtsFilterAll;
            break;
        case 1:
            filterType = MTETShirtsFilterWear;
            break;
        case 2:
            filterType = MTETShirtsFilterWash;
            break;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([userDefaults integerForKey:kMTETShirtsFilterType] != filterType) {
        [userDefaults setInteger:filterType forKey:kMTETShirtsFilterType];
        [userDefaults synchronize];
        
        [self configureForFilterType:filterType];
        [self setManagedObjectContext:self.managedObjectContext];
        [self.collectionView reloadData];
    }
}

@end
