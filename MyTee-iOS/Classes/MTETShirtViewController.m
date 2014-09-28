//
//  MTETShirtViewController.m
//  mytee
//
//  Created by Vincent Tourraine on 2/2/12.
//  Copyright (c) 2012 Studio AMANgA. All rights reserved.
//

#import "MTETShirtViewController.h"

@import QuartzCore;

#import <AFNetworking.h>

#import <SDWebImage/UIImageView+WebCache.h>

#import <RNGridMenu.h>
#import <Colours.h>

#import "MTETShirt.h"
#import "MTEStore.h"
#import "MTEWash.h"
#import "MTEWear.h"

#import "MTEWearWashViewController.h"
#import "MTEStoreViewController.h"
#import "MTEAuthenticationManager.h"
#import "MTEMyTeeAPIClient.h"

@interface MTETShirtViewController () <RNGridMenuDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *noteIconImageView;
@property (weak, nonatomic) IBOutlet UIButton *storeButton;
@property (weak, nonatomic) IBOutlet UIButton *wearButton;
@property (weak, nonatomic) IBOutlet UIButton *washButton;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *tagsLabel;
@property (weak, nonatomic) IBOutlet UILabel *noteLabel;
@property (strong, nonatomic) NSDateFormatter * dateFormatter;
@property (strong, nonatomic) UIPopoverController * masterPopoverController;

- (IBAction)didPressAction:(id)sender;
- (NSString*)relativeDescriptionForDate:(NSDate*)date;
- (IBAction)presentStoreController:(id)sender;

@end


@implementation MTETShirtViewController

#pragma mark - View lifecycle

- (void)setTshirt:(MTETShirt *)newTShirt
{
    if (_tshirt != newTShirt) {
        _tshirt = newTShirt;

        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)configureView
{
    if (!self.tshirt) {
        for (UIView *view in self.view.subviews) {
            view.hidden = YES;
        }
    }
    else {
        for (UIView *view in self.view.subviews) {
            view.hidden = NO;
        }

        self.title = self.tshirt.name;

        self.sizeLabel.layer.borderWidth  = 1;
        self.sizeLabel.layer.borderColor  = [UIColor blackColor].CGColor;
        self.sizeLabel.layer.cornerRadius = CGRectGetWidth(self.sizeLabel.frame)/2;
        self.sizeLabel.text = self.tshirt.size;
        self.tagsLabel.text = self.tshirt.tags;

        NSMutableString * ratingString = [NSMutableString stringWithString:@""];
        NSUInteger i = 0;
        NSUInteger rating = [self.tshirt.rating intValue];
        for( ; i<rating ; i++) {
            [ratingString appendString:@"★"];
        }
        for( ; i<5 ; i++) {
            [ratingString appendString:@"☆"];
        }

        self.ratingLabel.text = ratingString;

        if (self.tshirt.note.length > 0) {
            CGSize noteSize = [self.tshirt.note boundingRectWithSize:CGSizeMake(self.noteLabel.frame.size.width, CGFLOAT_MAX)
                                                             options:kNilOptions
                                                          attributes:@{NSFontAttributeName: self.noteLabel.font}
                                                             context:nil].size;
            self.noteLabel.frame = CGRectMake(self.noteLabel.frame.origin.x, self.noteLabel.frame.origin.y, self.noteLabel.frame.size.width, noteSize.height);
            self.noteLabel.text = self.tshirt.note;
            self.noteIconImageView.hidden = NO;
        }
        else {
            self.noteLabel.text = @"";
            self.noteIconImageView.hidden = YES;
        }

        [self.storeButton setTitle:self.tshirt.store.name forState:UIControlStateNormal];
        self.storeButton.enabled = ![self.tshirt.store.identifier isEqualToString:MTEUnknownStoreIdentifier];

        MTEWear *mostRecentWear = [self.tshirt mostRecentWear];
        if (mostRecentWear) {
            [self.wearButton setTitle:[NSString stringWithFormat:@"Last worn %@", [self relativeDescriptionForDate:mostRecentWear.date]]
                             forState:UIControlStateNormal];
        }
        else {
            [self.wearButton setTitle:@"Never worn before" forState:UIControlStateNormal];
        }

        MTEWash *mostRecentWash = [self.tshirt mostRecentWash];
        if (mostRecentWash) {
            [self.washButton setTitle:[NSString stringWithFormat:@"Last washed %@", [self relativeDescriptionForDate:mostRecentWash.date]]
                             forState:UIControlStateNormal];
        }
        else {
            [self.washButton setTitle:@"Never washed before" forState:UIControlStateNormal];
        }

        [self.tshirtImageView sd_setImageWithURL:[NSURL URLWithString:self.tshirt.image_url]
                                placeholderImage:nil options:kNilOptions];

        self.mainScrollView.contentSize = CGSizeMake((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 540 : self.view.frame.size.width, self.noteLabel.frame.origin.y+self.noteLabel.frame.size.height+50);
    }
}

- (NSString*)relativeDescriptionForDate:(NSDate*)date
{
    NSInteger nbDaysAgo = (int)[date timeIntervalSinceNow]/(-60*60*24);
    
    if (nbDaysAgo == 0)
        return @"today";
    else if (nbDaysAgo == 1)
        return @"yesterday";
    
    return [NSString stringWithFormat:@"%d days ago", nbDaysAgo];
}

- (IBAction)presentStoreController:(id)sender
{
    if ([self.tshirt.store.type isEqualToString:@"Retail"]) {
        [self performSegueWithIdentifier:@"MTEStoreRetailSegue" sender:nil];
    }
    else if ([self.tshirt.store.type isEqualToString:@"Web"]) {
        [self performSegueWithIdentifier:@"MTEStoreOnlineSegue" sender:nil];
    }
    else {
        [self performSegueWithIdentifier:@"MTEStoreSegue" sender:nil];
    }
}

- (IBAction)didPressAction:(id)sender
{
    UIImage *wearImage = [[UIImage imageNamed:@"IconTShirt"]
                          imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage *washImage = [[UIImage imageNamed:@"IconWash"]
                          imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    RNGridMenuItem *wearItem = [[RNGridMenuItem alloc] initWithImage:wearImage
                                                               title:@"Wear Today"];
    RNGridMenuItem *washItem = [[RNGridMenuItem alloc] initWithImage:washImage
                                                               title:@"Wash Today"];

    RNGridMenu *menu = [[RNGridMenu alloc] initWithItems:@[wearItem, washItem]];
    menu.menuView.tintColor = [UIColor palePurpleColor];
    menu.highlightColor     = [UIColor coolPurpleColor];
    menu.delegate           = self;

    [menu showInViewController:self center:self.tshirtImageView.center];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.doesRelativeDateFormatting = YES;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Dismiss", nil)
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(dismissViewController:)];
        self.navigationItem.leftBarButtonItem = item;
    }

    [self configureView];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"MTEStoreSegue"] ||
        [segue.identifier isEqualToString:@"MTEStoreRetailSegue"] ||
        [segue.identifier isEqualToString:@"MTEStoreOnlineSegue"]) {
        MTEStoreViewController *viewController = segue.destinationViewController;
        viewController.store = self.tshirt.store;
    }
}

- (IBAction)dismissViewController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)presentWearViewController:(id)sender
{
    MTEWearWashViewController *viewController = [[MTEWearWashViewController alloc] init];
    viewController.datesObjects = self.tshirt.wearsSortedByDate;
    viewController.title = NSLocalizedString(@"Wear", nil);
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)presentWashViewController:(id)sender
{
    MTEWearWashViewController *viewController = [[MTEWearWashViewController alloc] init];
    viewController.datesObjects = self.tshirt.washsSortedByDate;
    viewController.title = NSLocalizedString(@"Wash", nil);
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Grid menu delegate

- (void)gridMenu:(RNGridMenu *)gridMenu willDismissWithSelectedItem:(RNGridMenuItem *)item atIndex:(NSInteger)itemIndex
{
    NSDictionary * params = @{@"login":   [MTEAuthenticationManager emailFromKeychain],
                              @"password":[MTEAuthenticationManager passwordFromKeychain]};
    NSString *path;
    
    switch (itemIndex) {
        case 0:
            // Wear
            path = [NSString stringWithFormat:@"tshirt/%@/wear", self.tshirt.identifier];
            break;
            
        case 1:
            // Wash
            path = [NSString stringWithFormat:@"tshirt/%@/wash", self.tshirt.identifier];
            break;
    }
    
    if (path) {
        [[MTEMyTeeAPIClient sharedClient] postPath:path
                                        parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
                                            [self dismissViewControllerAnimated:YES completion:nil];
                                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                            [[[UIAlertView alloc] initWithTitle:@"Error"
                                                                        message:[NSString stringWithFormat:@"%@ (%@)", [error localizedDescription], [error localizedRecoverySuggestion]]
                                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                        }];
    }
}

@end
