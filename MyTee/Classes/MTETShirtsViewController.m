//
//  MTETShirtsViewController.m
//  mytee
//
//  Created by Vincent Tourraine on 1/31/12.
//  Copyright (c) 2012 Studio AMANgA. All rights reserved.
//

#import "MTETShirtsViewController.h"

#import "MTETShirt.h"
#import "MTETShirtExplorer.h"
#import "MTEAuthenticationManager.h"
#import "MTEAppDelegate.h"
#import "MTESyncManager.h"

#import "MBProgressHUD.h"
#import "MTEConstView.h"

#import "MTETShirtViewController.h"
#import "MTESettingsViewController.h"
#import "MTELoginViewController.h"
#import "MTETShirtsFilterViewController.h"

#import <AFNetworking.h>
#import <QuartzCore/QuartzCore.h>

@interface MTETShirtsViewController () <UIPopoverControllerDelegate, MTETShirtExplorerDelegate>

@property (nonatomic, strong) UIPopoverController *filterPopoverController;

- (void)startRefresh:(id)sender;

@end


@implementation MTETShirtsViewController

#pragma mark - View lifecycle

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    
    self.tshirtExplorer = [MTETShirtExplorer new];
    self.tshirtExplorer.delegate = self;
    [self.tshirtExplorer setupFetchedResultsControllerWithContext:managedObjectContext];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        self.detailViewController = (MTETShirtViewController*)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    UIImage *woodTexture;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        woodTexture = [UIImage imageNamed:(UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) ? @"shelves-portrait" : @"shelves-landscape"];
    else
        woodTexture = [UIImage imageNamed:@"shelves"];
    UIColor *woodColor = [UIColor colorWithPatternImage:woodTexture];
    self.collectionView.backgroundColor = woodColor;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(startRefresh:)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];
    
    [self.tshirtExplorer fetchData];
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

#pragma mark - Actions

- (void)startRefresh:(id)sender
{
    [self.syncManager syncSuccess:^{
        if ([sender isKindOfClass:[UIRefreshControl class]])
            [(UIRefreshControl *)sender endRefreshing];
        
        [self.tshirtExplorer fetchData];
        [self.collectionView reloadData];
    } failure:^(NSError *error) {
        if ([sender isKindOfClass:[UIRefreshControl class]])
            [(UIRefreshControl *)sender endRefreshing];
    }];
}

- (IBAction)showFilterViewController:(id)sender
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (self.filterPopoverController) {
            [self.filterPopoverController dismissPopoverAnimated:YES];
            self.filterPopoverController = nil;
        }
        else {
            MTETShirtsFilterViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MTETShirtsFilterViewController"];
            viewController.delegate = self;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            self.filterPopoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
            self.filterPopoverController.delegate = self;
            [self.filterPopoverController presentPopoverFromRect:CGRectMake(0, 0, 44, 44) inView:self.navigationController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
    else {
//        [self.slidingViewController anchorTopViewTo:ECRight];
    }
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
        MTETShirt *tshirt      = [self.tshirtExplorer tshirtAtIndex:indexPath.row];
        viewController.tshirt = tshirt;
    }
    else if ([segue.identifier isEqualToString:@"MTEFilterSegue"])
    {
        UINavigationController *navigationController = segue.destinationViewController;
        MTETShirtsFilterViewController *viewController = (MTETShirtsFilterViewController*)navigationController.topViewController;
        viewController.delegate = self;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
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
    return 1;
}

- (int)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.tshirtExplorer numberOfTShirts];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MTETShirtCellID" forIndexPath:indexPath];
    
    MTETShirt *tshirt = [self.tshirtExplorer tshirtAtIndex:indexPath.row];
    
    UIImageView *tshirtImageView = nil;
    if ([[cell.contentView.subviews lastObject] isMemberOfClass:[UIImageView class]])
        tshirtImageView = [cell.contentView.subviews lastObject];
    
    if (!tshirtImageView)
    {
        tshirtImageView = [[UIImageView alloc] init];
        tshirtImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            CGFloat tshirtSize = cell.bounds.size.width - 2*20;
            tshirtImageView.frame = CGRectMake(10, (cell.bounds.size.height - tshirtSize)/2 + 8, tshirtSize, tshirtSize);
        }
        else
        {
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [self.detailViewController.navigationController popToRootViewControllerAnimated:YES];
        
        MTETShirt *tshirt = [self.tshirtExplorer tshirtAtIndex:indexPath.row];
        self.detailViewController.tshirt = tshirt;
    }
}

#pragma mark - Login

- (void)loginViewControllerDidLoggedIn:(MTELoginViewController *)loginViewController
{
    [self.tshirtExplorer fetchData];
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
    
    [self.tshirtExplorer fetchData];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Filter view delegate

- (void)tshirtsFilterViewControllerDidChangeFilter:(MTETShirtsFilterViewController *)filterController
{
    [self.collectionView reloadData];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.filterPopoverController dismissPopoverAnimated:YES];
        self.filterPopoverController = nil;
    }
    else {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
    
    [self.collectionView setContentOffset:CGPointZero animated:NO];
}

#pragma mark - Popover controller

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.filterPopoverController = nil;
}

#pragma mark - TShirt explorer delegate

- (void)tshirtExplorerDidUpdateData:(MTETShirtExplorer *)tshirtExplorer
{
    [self.collectionView reloadData];
}

@end
