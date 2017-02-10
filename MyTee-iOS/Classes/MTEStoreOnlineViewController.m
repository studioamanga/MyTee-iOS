//
//  MTEStoreOnlineViewController.m
//  mytee
//
//  Created by Vincent Tourraine on 6/11/12.
//  Copyright (c) 2012-2017 Studio AMANgA. All rights reserved.
//

#import "MTEStoreOnlineViewController.h"

#import "MTEStore.h"

@interface MTEStoreOnlineViewController ()

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@end


@implementation MTEStoreOnlineViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webView.layer.borderWidth  = 1;
    self.webView.layer.cornerRadius = 4;

    if (self.store.url.length > 0) {
        NSURL *URL = [NSURL URLWithString:self.store.url];
        NSURLRequest *URLRequest = [NSURLRequest requestWithURL:URL];
        [self.webView loadRequest:URLRequest];
    }
}


#pragma mark - Actions

- (IBAction)presentActionSheet:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open in Safari", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *URL = [NSURL URLWithString:self.store.url];
        [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:^(BOOL success) {}];
    }]];

    [self presentViewController:alertController animated:YES completion:nil];
}

@end
