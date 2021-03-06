//
//  MTETShirtViewController.h
//  mytee
//
//  Created by Vincent Tourraine on 2/2/12.
//  Copyright (c) 2012-2017 Studio AMANgA. All rights reserved.
//

@import UIKit;
@class MTETShirt;

@interface MTETShirtViewController : UIViewController <UISplitViewControllerDelegate>

@property (nonatomic, strong) MTETShirt *tshirt;

@property (nonatomic, weak) IBOutlet UIScrollView *mainScrollView;
@property (nonatomic, weak) IBOutlet UIImageView  *tshirtImageView;

- (void)configureView;
- (IBAction)dismissViewController:(id)sender;
- (IBAction)presentWearViewController:(id)sender;
- (IBAction)presentWashViewController:(id)sender;

@end
