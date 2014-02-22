//
//  MTEWearWashViewController.m
//  mytee
//
//  Created by Vincent Tourraine on 2/2/12.
//  Copyright (c) 2012-2014 Studio AMANgA. All rights reserved.
//

#import "MTEWearWashViewController.h"

@implementation MTEWearWashViewController

#pragma mark - View lifecycle

- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerClass:UITableViewCell.class
           forCellReuseIdentifier:@"MTEDateCell"];

    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateStyle = NSDateFormatterFullStyle;
    self.dateFormatter.doesRelativeDateFormatting = YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.datesObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTEDateCell"];

    id object = self.datesObjects[indexPath.row];
    cell.textLabel.text  = [[self.dateFormatter stringFromDate:[object date]] capitalizedString];
    cell.imageView.image = [UIImage imageNamed:@"IconCalendar"];
    cell.selectionStyle  = UITableViewCellSelectionStyleNone;

    return cell;
}

@end
