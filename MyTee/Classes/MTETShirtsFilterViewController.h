//
//  MTETShirtsFilterViewController.h
//  mytee
//
//  Created by Vincent Tourraine on 9/8/12.
//  Copyright (c) 2012 Studio AMANgA. All rights reserved.
//

@import UIKit;

@protocol MTETShirtsFilterViewDelegate;

@interface MTETShirtsFilterViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id <MTETShirtsFilterViewDelegate> delegate;

@end

@protocol MTETShirtsFilterViewDelegate <NSObject>

- (void)tshirtsFilterViewControllerDidChangeFilter:(MTETShirtsFilterViewController *)filterController;

@end