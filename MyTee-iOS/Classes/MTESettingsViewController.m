//
//  MTESettingsViewController.m
//  mytee
//
//  Created by Vincent Tourraine on 2/15/12.
//  Copyright (c) 2012-2016 Studio AMANgA. All rights reserved.
//

#import "MTESettingsViewController.h"

#import "MTEAuthenticationManager.h"
#import "MTESettingsManager.h"
#import "MTESettingCell.h"
#import "MTESettingSwitchCell.h"

enum MTESettingsViewSections {
    MTESettingsViewSectionReminders = 0,
    MTESettingsViewSectionSyncNow,
    MTESettingsViewSectionLogOut,
    MTESettingsViewNumberOfSections
};

@implementation MTESettingsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    }
    else {
        self.emailLabel.textColor = [UIColor blackColor];
        self.emailLabel.shadowColor = [UIColor clearColor];

        UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStylePlain target:self action:@selector(didPressCancel:)];
        self.navigationItem.rightBarButtonItem = closeItem;
    }

    NSString *email = [MTEAuthenticationManager emailFromKeychain];
    self.emailLabel.text = (email) ? email : NSLocalizedString(@"You are not logged in", nil);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return MTESettingsViewNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case MTESettingsViewSectionReminders:
            return 2;

        case MTESettingsViewSectionSyncNow:
        case MTESettingsViewSectionLogOut:
            return 1;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    switch (indexPath.section) {
        case MTESettingsViewSectionReminders: {
            switch (indexPath.row) {
                case 0:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"MTESettingsReminderSwitchCell" forIndexPath:indexPath];
                    ((MTESettingSwitchCell *)cell).switchControl.on = [MTESettingsManager isRemindersActive];
                    [((MTESettingSwitchCell *)cell).switchControl removeTarget:self action:@selector(remindersSwitchValueDidChange:) forControlEvents:UIControlEventValueChanged];
                    [((MTESettingSwitchCell *)cell).switchControl addTarget:self action:@selector(remindersSwitchValueDidChange:) forControlEvents:UIControlEventValueChanged];
                    break;

                case 1:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"MTESettingsReminderTimeCell" forIndexPath:indexPath];
                    ((MTESettingCell *)cell).label.text = [NSString stringWithFormat:@"Everyday at %@ AM", @([MTESettingsManager remindersHour])];
                    for (UIView *subview in cell.contentView.subviews) {
                        subview.alpha = ([MTESettingsManager isRemindersActive]) ? 1 : 0.5;
                    }
                    break;
            }
            break;
        }

        case MTESettingsViewSectionSyncNow:
            cell = [tableView dequeueReusableCellWithIdentifier:@"MTESettingsActionCell" forIndexPath:indexPath];
            cell.textLabel.text = NSLocalizedString(@"Sync Now", nil);
            break;

        case MTESettingsViewSectionLogOut:
            cell = [tableView dequeueReusableCellWithIdentifier:@"MTESettingsActionCell" forIndexPath:indexPath];
            cell.textLabel.text = NSLocalizedString(@"Log Out", nil);
            break;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case MTESettingsViewSectionReminders:
            break;

        case MTESettingsViewSectionSyncNow:
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self.delegate settingsViewControllerShouldSyncNow:self];
            break;

        case MTESettingsViewSectionLogOut: {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];

            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure you want to log out?", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Log Out", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.delegate settingsViewControllerShouldLogOut:self];
            }]];

            [self presentViewController:alertController animated:YES completion:nil];
            break;
        }
    }
}

#pragma mark - Switch delegate

- (IBAction)remindersSwitchValueDidChange:(UISwitch *)sender {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:MTESettingsViewSectionReminders];
    UITableViewCell *reminderTimeCell = [self.tableView cellForRowAtIndexPath:indexPath];

    [UIView animateWithDuration:0.3 animations:^{
        for (UIView *subview in reminderTimeCell.contentView.subviews)
            subview.alpha = (sender.isOn) ? 1 : 0.5;
    }];

    [MTESettingsManager setRemindersActive:sender.isOn];
}


#pragma mark - Sync

- (void)syncFailed {}

- (void)updateDidStart {}

- (IBAction)didPressDone:(id)sender {
    [self.delegate settingsViewControllerShouldClose:self];
}

- (IBAction)didPressCancel:(id)sender {
    [self.delegate settingsViewControllerShouldClose:self];
}

@end
