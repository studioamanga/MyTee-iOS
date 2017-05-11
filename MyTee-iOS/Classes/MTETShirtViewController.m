//
//  MTETShirtViewController.m
//  mytee
//
//  Created by Vincent Tourraine on 2/2/12.
//  Copyright (c) 2012-2017 Studio AMANgA. All rights reserved.
//

#import "MTETShirtViewController.h"

@import UserNotifications;
@import QuartzCore;

#import <AFNetworking.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <RNGridMenu.h>
#import <Colours.h>
#import <ColorArt/SLColorArt.h>
#import <SVProgressHUD.h>

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
@property (weak, nonatomic) IBOutlet UIImageView *tagsImageView;
@property (weak, nonatomic) IBOutlet UILabel *noteLabel;
@property (weak, nonatomic) IBOutlet UIImageView *noteImageView;
@property (strong, nonatomic) NSDateFormatter * dateFormatter;

@property (nonatomic, strong, nullable) NSArray <id <UIPreviewActionItem>> *previewActions;

@end


@implementation MTETShirtViewController

#pragma mark - View life cycle

- (void)setTshirt:(MTETShirt *)newTShirt {
    if (_tshirt != newTShirt) {
        _tshirt = newTShirt;

        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    if (self.tshirt == nil) {
        for (UIView *view in self.view.subviews) {
            view.hidden = YES;
        }

        return;
    }

    for (UIView *view in self.view.subviews) {
        view.hidden = NO;
    }

    self.title = self.tshirt.name;

    self.sizeLabel.text = self.tshirt.size;
    self.tagsLabel.text = self.tshirt.tags;

    self.ratingLabel.text = ({
        NSMutableString *ratingString = [NSMutableString stringWithString:@""];
        NSUInteger i = 0;
        NSUInteger rating = [self.tshirt.rating intValue];
        for( ; i < rating ; i++) {
            [ratingString appendString:@"★"];
        }
        for( ; i < 5 ; i++) {
            [ratingString appendString:@"☆"];
        }
        ratingString;
    });

    if (self.tshirt.note.length > 0) {
        self.noteLabel.text = self.tshirt.note;
        self.noteImageView.hidden = NO;
    }
    else {
        self.noteLabel.text = nil;
        self.noteImageView.hidden = YES;
    }

    [self.storeButton setTitle:self.tshirt.store.name forState:UIControlStateNormal];
    self.storeButton.enabled = ![self.tshirt.store.identifier isEqualToString:MTEUnknownStoreIdentifier];

    MTEWear *mostRecentWear = [self.tshirt mostRecentWear];
    if (mostRecentWear) {
        [self.wearButton setTitle:[NSString stringWithFormat:@"Last worn %@", [self relativeDescriptionForDate:mostRecentWear.date]] forState:UIControlStateNormal];
    }
    else {
        [self.wearButton setTitle:@"Never worn before" forState:UIControlStateNormal];
    }

    MTEWash *mostRecentWash = [self.tshirt mostRecentWash];
    if (mostRecentWash) {
        [self.washButton setTitle:[NSString stringWithFormat:@"Last washed %@ (%@ w)", [self relativeDescriptionForDate:mostRecentWash.date], [self.tshirt numberOfWearsSinceLastWash]] forState:UIControlStateNormal];
    }
    else {
        [self.washButton setTitle:@"Never washed before" forState:UIControlStateNormal];
    }

    [self.tshirtImageView sd_setImageWithURL:[NSURL URLWithString:self.tshirt.image_url] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        SLColorArt *colorArt = [[SLColorArt alloc] initWithImage:image];
        self.view.backgroundColor = colorArt.backgroundColor;

        self.sizeLabel.textColor = colorArt.primaryColor;
        self.ratingLabel.textColor = colorArt.primaryColor;

        self.storeButton.tintColor = colorArt.secondaryColor;
        [self.storeButton setTitleColor:colorArt.primaryColor forState:UIControlStateNormal];
        self.wearButton.tintColor = colorArt.secondaryColor;
        [self.wearButton setTitleColor:colorArt.primaryColor forState:UIControlStateNormal];
        self.washButton.tintColor = colorArt.secondaryColor;
        [self.washButton setTitleColor:colorArt.primaryColor forState:UIControlStateNormal];

        self.tagsImageView.tintColor = colorArt.secondaryColor;
        self.tagsLabel.textColor = colorArt.primaryColor;
        self.noteImageView.tintColor = colorArt.secondaryColor;
        self.noteLabel.textColor = colorArt.primaryColor;
    }];

    self.mainScrollView.contentSize = CGSizeMake((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 540 : self.view.frame.size.width, self.noteLabel.frame.origin.y+self.noteLabel.frame.size.height+50);
}

- (NSString *)relativeDescriptionForDate:(NSDate *)date {
    NSInteger nbDaysAgo = [date timeIntervalSinceNow] / (-60 * 60 * 24);

    if (nbDaysAgo == 0) {
        return @"today";
    }
    else if (nbDaysAgo == 1) {
        return @"yesterday";
    }

    return [NSString stringWithFormat:@"%@ days ago", @(nbDaysAgo)];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.doesRelativeDateFormatting = YES;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIBarButtonItemStylePlain target:self action:@selector(dismissViewController:)];
        self.navigationItem.leftBarButtonItem = item;
    }

    [self configureView];
}

#pragma mark - Actions

- (IBAction)presentStoreController:(id)sender {
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

- (IBAction)didPressAction:(id)sender {
    UIImage *wearImage = [[UIImage imageNamed:@"IconTShirt"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage *washImage = [[UIImage imageNamed:@"IconWash"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    RNGridMenuItem *wearItem = [[RNGridMenuItem alloc] initWithImage:wearImage title:NSLocalizedString(@"Wear Today", nil)];
    RNGridMenuItem *washItem = [[RNGridMenuItem alloc] initWithImage:washImage title:NSLocalizedString(@"Wash Today", nil)];

    RNGridMenu *menu = [[RNGridMenu alloc] initWithItems:@[wearItem, washItem]];
    menu.menuView.tintColor = [UIColor lightGrayColor];
    menu.highlightColor = [UIColor blackColor];
    menu.delegate = self;

    [menu showInViewController:self center:self.tshirtImageView.center];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MTEStoreSegue"] ||
        [segue.identifier isEqualToString:@"MTEStoreRetailSegue"] ||
        [segue.identifier isEqualToString:@"MTEStoreOnlineSegue"]) {
        MTEStoreViewController *viewController = segue.destinationViewController;
        viewController.store = self.tshirt.store;
    }
}

- (IBAction)dismissViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)presentWearViewController:(id)sender {
    MTEWearWashViewController *viewController = [[MTEWearWashViewController alloc] init];
    viewController.datesObjects = self.tshirt.wearsSortedByDate;
    viewController.title = NSLocalizedString(@"Wear", nil);
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)presentWashViewController:(id)sender {
    MTEWearWashViewController *viewController = [[MTEWearWashViewController alloc] init];
    viewController.datesObjects = self.tshirt.washsSortedByDate;
    viewController.title = NSLocalizedString(@"Wash", nil);
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)presentAlertWithError:(nullable NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:[NSString stringWithFormat:@"%@ (%@)", error.localizedDescription, error.localizedRecoverySuggestion] preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Grid menu delegate

- (void)gridMenu:(RNGridMenu *)gridMenu willDismissWithSelectedItem:(RNGridMenuItem *)item atIndex:(NSInteger)itemIndex {
    NSDictionary * params = @{@"login": [MTEAuthenticationManager emailFromKeychain],
                              @"password":[MTEAuthenticationManager passwordFromKeychain]};
    NSString *path = [NSString stringWithFormat:@"tshirt/%@/%@", self.tshirt.identifier, itemIndex == 0 ? @"wear" : @"wash"];

    [[MTEMyTeeAPIClient sharedClient]
     postPath:path
     parameters:params
     success:^(AFHTTPRequestOperation *operation, id responseObject) {
         [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
         [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];

         [SVProgressHUD showSuccessWithStatus:itemIndex == 0 ? NSLocalizedString(@"Wearing Today", nil) : NSLocalizedString(@"Washed Today", nil)];
         // [self dismissViewControllerAnimated:YES completion:nil];
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         [self presentAlertWithError:error];
     }];
}

#pragma mark -

- (NSArray <id <UIPreviewActionItem>> *)previewActionItems {
    if (!self.previewActions) {
        self.previewActions =
        @[[UIPreviewAction
           actionWithTitle:NSLocalizedString(@"Wear Today", nil)
           style:UIPreviewActionStyleDefault
           handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
               NSDictionary * params = @{@"login": [MTEAuthenticationManager emailFromKeychain],
                                         @"password":[MTEAuthenticationManager passwordFromKeychain]};
               NSString *path = [NSString stringWithFormat:@"tshirt/%@/wear", self.tshirt.identifier];

               [[MTEMyTeeAPIClient sharedClient]
                postPath:path
                parameters:params
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
                    [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];

                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Wearing Today", nil)];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [self presentAlertWithError:error];
                }];
           }]];
    }

    return self.previewActions;
}

@end
