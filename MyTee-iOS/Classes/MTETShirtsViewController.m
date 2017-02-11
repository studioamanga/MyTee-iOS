//
//  MTETShirtsViewController.m
//  mytee
//
//  Created by Vincent Tourraine on 1/31/12.
//  Copyright (c) 2012-2016 Studio AMANgA. All rights reserved.
//

#import "MTETShirtsViewController.h"

@import QuartzCore;

#import <AFNetworking.h>

#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDImageCache.h>

#import <SVProgressHUD.h>
#import <RNGridMenu.h>
#import <Colours.h>

#import "MTETShirt.h"
#import "MTEAuthenticationManager.h"
#import "MTEAppDelegate.h"
#import "MTESyncManager.h"

#import "MTEConstView.h"

#import "MTETShirtViewController.h"
#import "MTESettingsViewController.h"
#import "MTELoginViewController.h"

@interface MTETShirtsViewController () <UIPopoverControllerDelegate, NSFetchedResultsControllerDelegate, RNGridMenuDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end


@implementation MTETShirtsViewController

#pragma mark - View lifecycle

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MTETShirt class])];

    NSUserDefaults *userDefaults    = [NSUserDefaults standardUserDefaults];
    MTETShirtsFilterType filterType = [userDefaults integerForKey:kMTETShirtsFilterType];
    NSSortDescriptor *sortDescriptor;
    NSString *sectionNameKeyPath;

    switch (filterType) {
        case MTETShirtsFilterWash:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"numberOfWearsSinceLastWash" ascending:NO];
            sectionNameKeyPath = @"numberOfWearsSinceLastWash";
            break;

        case MTETShirtsFilterWear:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"color" ascending:YES];
            break;

        case MTETShirtsFilterAll:
        default:
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"color" ascending:YES];
            sectionNameKeyPath = @"color";
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
    if (!result) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor blackColor];
    [refreshControl addTarget:self action:@selector(startRefresh:)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    MTETShirtsFilterType filterType = [userDefaults integerForKey:kMTETShirtsFilterType];
    [self configureForFilterType:filterType];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (![MTEAuthenticationManager emailFromKeychain]) {
        [self showLoginViewController:nil];
    }
}

- (void)configureForFilterType:(MTETShirtsFilterType)filterType {
    NSString *filterIconName;

    switch (filterType) {
        case MTETShirtsFilterWash:
            self.title     = @"T-Shirts to Wash";
            filterIconName = @"IconWash";
            break;

        case MTETShirtsFilterWear:
            self.title     = @"T-Shirt to Wear";
            filterIconName = @"118-coat-hanger";
            break;

        case MTETShirtsFilterAll:
        default:
            self.title     = @"My T-Shirts";
            filterIconName = @"IconCabinet";
            break;
    }

    UIBarButtonItem *filterBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:filterIconName]
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(showFilterViewController:)];
    self.navigationItem.leftBarButtonItem = filterBarButtonItem;
}


#pragma mark - Actions

- (void)startRefresh:(id)sender {
    [self.syncManager syncSuccess:^(UIBackgroundFetchResult result){
        if ([sender isKindOfClass:UIRefreshControl.class]) {
            [(UIRefreshControl *)sender endRefreshing];
        }

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        MTETShirtsFilterType filterType = [userDefaults integerForKey:kMTETShirtsFilterType];
        [self configureForFilterType:filterType];
    } failure:^(NSError *error) {
        if ([sender isKindOfClass:UIRefreshControl.class]) {
            [(UIRefreshControl *)sender endRefreshing];
        }
    }];
}

- (IBAction)showFilterViewController:(id)sender {
    UIImage *allImage  = [[UIImage imageNamed:@"IconCabinet"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage *wearImage = [[UIImage imageNamed:@"IconTShirt"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage *washImage = [[UIImage imageNamed:@"IconWash"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    RNGridMenuItem *allItem  = [[RNGridMenuItem alloc] initWithImage:allImage title:NSLocalizedString(@"All", nil)];
    RNGridMenuItem *wearItem = [[RNGridMenuItem alloc] initWithImage:wearImage title:NSLocalizedString(@"Wear", nil)];
    RNGridMenuItem *washItem = [[RNGridMenuItem alloc] initWithImage:washImage title:NSLocalizedString(@"Wash", nil)];

    NSArray *items = @[wearItem, washItem, allItem];
    RNGridMenu *menu = [[RNGridMenu alloc] initWithItems:items];
    menu.menuView.tintColor = [UIColor orangeColor];
    menu.highlightColor = [UIColor blackColor];
    menu.delegate = self;

    [menu showInViewController:self center:self.view.center];
}

- (IBAction)showSettingsViewController:(id)sender
{
    if (![MTEAuthenticationManager emailFromKeychain]) {
        [self showLoginViewController:sender];
        return;
    }

    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"Storyboard_iPhone" bundle:[NSBundle mainBundle]];
    }
    else {
        storyboard = self.storyboard;
    }

    UINavigationController *settingsNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"MTESettingsNavigationController"];
    settingsNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    MTESettingsViewController *viewController = (MTESettingsViewController*)settingsNavigationController.topViewController;
    viewController.delegate = self;
    [self presentViewController:settingsNavigationController animated:YES completion:nil];
}

- (IBAction)showLoginViewController:(id)sender
{
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"Storyboard_iPhone" bundle:[NSBundle mainBundle]];
    }
    else {
        storyboard = self.storyboard;
    }

    UINavigationController *settingsNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"MTELoginNavigationController"];
    settingsNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    MTELoginViewController *viewController = (MTELoginViewController*)settingsNavigationController.topViewController;
    viewController.delegate = self;
    [self presentViewController:settingsNavigationController animated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"MTETShirtSegue"]) {
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

#pragma mark - Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MTETShirtCellID" forIndexPath:indexPath];

    MTETShirt *tshirt = [self.fetchedResultsController objectAtIndexPath:indexPath];

    UIImageView *tshirtImageView = nil;
    if ([cell.contentView.subviews.lastObject isMemberOfClass:UIImageView.class]) {
        tshirtImageView = cell.contentView.subviews.lastObject;
    }

    if (!tshirtImageView) {
        tshirtImageView = [[UIImageView alloc] init];
        tshirtImageView.contentMode = UIViewContentModeScaleAspectFit;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            CGFloat tshirtSize = cell.bounds.size.width - 2*20;
            tshirtImageView.frame = CGRectMake(10, (cell.bounds.size.height - tshirtSize)/2 + 8, tshirtSize, tshirtSize);
        }
        else {
            CGFloat margin = 6;
            CGFloat tshirtSize = cell.bounds.size.width - 2*margin;
            tshirtImageView.frame = CGRectMake(margin, (cell.bounds.size.height - tshirtSize)/2 + margin,
                                               tshirtSize, tshirtSize);
        }

        [cell.contentView addSubview:tshirtImageView];
    }

    NSURL   *imageURL = [NSURL URLWithString:tshirt.image_url];
    UIImage *image    = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:tshirt.image_url];
    if (image) {
        tshirtImageView.image = image;
    }
    else {
        [tshirtImageView sd_setImageWithURL:imageURL
                           placeholderImage:nil
                                    options:kNilOptions];
    }

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedCellIndexPath = indexPath;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard_iPhone" bundle:[NSBundle mainBundle]];

        MTETShirtViewController *tshirtViewController = [storyboard instantiateViewControllerWithIdentifier:@"MTETShirtViewController"];
        tshirtViewController.tshirt = [self.fetchedResultsController objectAtIndexPath:indexPath];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:tshirtViewController];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navigationController animated:YES completion:nil];
    }
    else {
        MTETShirtViewController *tshirtViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MTETShirtViewController"];
        tshirtViewController.tshirt = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.navigationController pushViewController:tshirtViewController animated:YES];
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
    [SVProgressHUD showErrorWithStatus:@"Sync Failed"];
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
    MTEAppDelegate *appDelegate = (MTEAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate resetManagedObjectContext];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Popover controller

#pragma mark - Grid menu delegate

- (void)gridMenu:(RNGridMenu *)gridMenu willDismissWithSelectedItem:(RNGridMenuItem *)item atIndex:(NSInteger)itemIndex
{
    MTETShirtsFilterType filterType;
    switch (itemIndex) {
        case 0:
            filterType = MTETShirtsFilterWear;
            break;
        case 1:
            filterType = MTETShirtsFilterWash;
            break;
        case 2:
            filterType = MTETShirtsFilterAll;
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
