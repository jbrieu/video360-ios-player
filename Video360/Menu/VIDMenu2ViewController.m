//
//  VIDMenu2ViewController.m
//  Video360
//
//  Created by Jean-Baptiste Rieu on 26/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import "VIDMenu2ViewController.h"
#import "VIDVideoPlayerViewController.h"

@interface VIDMenu2ViewController ()

@end

@implementation VIDMenu2ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark button management
- (IBAction)buttonZone7Touched:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://www.apple.com"];
    [[UIApplication sharedApplication] openURL:url];
}


- (IBAction)buttonZone8Touched:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)buttonZone9Touched:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://www.microsoft.com"];
    [[UIApplication sharedApplication] openURL:url];
}


#pragma mark launch actions
-(void) launchVideoWithURL:(NSURL*)url
{
    VIDVideoPlayerViewController *videoController = [[VIDVideoPlayerViewController alloc] initWithNibName:@"VIDVideoPlayerViewController" bundle:nil url:url];
    
    if(![[self presentedViewController] isBeingDismissed])
    {
        [self presentViewController:videoController animated:YES completion:nil];
    }
}

@end
