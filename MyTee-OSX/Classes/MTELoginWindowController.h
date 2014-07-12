//
//  MTELoginWindowController.h
//  mytee
//
//  Created by Vincent Tourraine on 12/07/14.
//  Copyright (c) 2014 Studio AMANgA. All rights reserved.
//

@import Cocoa;

@protocol MTELoginWindowDelegate;

@interface MTELoginWindowController : NSWindowController

@property (nonatomic, weak) IBOutlet NSTextField *emailTextField;
@property (nonatomic, weak) IBOutlet NSTextField *passwordTextField;

@property (nonatomic, weak) id <MTELoginWindowDelegate> delegate;

- (IBAction)login:(id)sender;

@end


@protocol MTELoginWindowDelegate <NSObject>

- (void)loginWindowController:(MTELoginWindowController *)windowController
                didEnterEmail:(NSString *)email
                     password:(NSString *)password;

@end