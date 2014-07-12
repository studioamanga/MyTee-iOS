//
//  MTELoginWindowController.m
//  mytee
//
//  Created by Vincent Tourraine on 12/07/14.
//  Copyright (c) 2014 Studio AMANgA. All rights reserved.
//

#import "MTELoginWindowController.h"

@interface MTELoginWindowController ()

@end

@implementation MTELoginWindowController

- (instancetype)init
{
    self = [super initWithWindowNibName:@"LoginWindow"];
    if (self) {
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (IBAction)login:(id)sender
{
    [self.delegate loginWindowController:self
                           didEnterEmail:self.emailTextField.stringValue
                                password:self.passwordTextField.stringValue];
}

@end
