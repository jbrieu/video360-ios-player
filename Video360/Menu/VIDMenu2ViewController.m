//
//  VIDMenu2ViewController.m
//  Video360
//
//  Created by Jean-Baptiste Rieu on 26/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import "VIDMenu2ViewController.h"


@interface VIDMenu2ViewController ()

@end

@implementation VIDMenu2ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.imageNames = @[@"menu02_A_ipad.png", @"menu02_B_ipad.png", @"menu02_C_ipad.png"];
    }
    return self;
}


#pragma mark button management
- (IBAction)buttonZone7Touched:(id)sender {
    [self openURLWithString:@"http://www.google.fr"];
}


- (IBAction)buttonZone8Touched:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)buttonZone9Touched:(id)sender {
    [self openURLWithString:@"http://www.microsoft.com"];
}



@end
