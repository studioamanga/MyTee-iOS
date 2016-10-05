//
//  MTEStoreRetailViewController.m
//  mytee
//
//  Created by Vincent Tourraine on 6/10/12.
//  Copyright (c) 2012-2016 Studio AMANgA. All rights reserved.
//

#import "MTEStoreRetailViewController.h"

@import MapKit;
@import CoreLocation;
@import QuartzCore;

#import "MTEStore.h"

@interface MTEStoreRetailViewController ()

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) CLGeocoder *geocoder;

@end


@implementation MTEStoreRetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.geocoder = [CLGeocoder new];

    self.mapView.layer.borderWidth  = 1;
    self.mapView.layer.cornerRadius = 4;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSString *geocodingAddress = [self storeLocation];

    if (geocodingAddress) {
        [self.geocoder
         geocodeAddressString:geocodingAddress
         completionHandler:^(NSArray *placemarks, NSError *error){
             if (!error && placemarks.count > 0) {
                 CLPlacemark *placemark = placemarks.firstObject;
                 MKCoordinateRegion region = MKCoordinateRegionMake(placemark.location.coordinate, MKCoordinateSpanMake(1, 1));
                 [self.mapView setRegion:region animated:YES];

                 MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
                 pointAnnotation.coordinate = placemark.location.coordinate;
                 pointAnnotation.title = self.store.name;
                 [self.mapView addAnnotation:pointAnnotation];
             }
         }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.mapView.delegate = nil;
    [self.geocoder cancelGeocode];
    self.geocoder = nil;
}


#pragma mark - Map view

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id)annotation {
    MKPinAnnotationView *newAnnotation = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotation1"];
    newAnnotation.pinTintColor = [UIColor redColor];
    newAnnotation.animatesDrop = YES;
    newAnnotation.canShowCallout = YES;
    [newAnnotation setSelected:YES animated:YES];

    return newAnnotation;
}

#pragma mark - Actions

- (NSString *)storeLocation {
    if (self.store.address.length > 0) {
        return self.store.address;
    }

    return self.store.name;
}

- (IBAction)presentActionSheet:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open in Maps", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *URLString = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@", self.storeLocation];
        NSURL *URL = [NSURL URLWithString:URLString];
        [[UIApplication sharedApplication] openURL:URL];
    }]];

    [self presentViewController:alertController animated:YES completion:nil];
}

@end
