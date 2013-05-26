//
//  VIDMenuViewController.m
//  Video360
//
//  Created by Jean-Baptiste Rieu on 26/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import "VIDMenuViewController.h"
#import "VIDVideoPlayerViewController.h"

@interface VIDMenuViewController ()


@end

@implementation VIDMenuViewController

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
- (IBAction)buttonZone1Touched:(id)sender {
    NSURL *url = [[NSBundle mainBundle]
                  URLForResource: @"demo" withExtension:@"mp4"];
    [self launchVideoWithURL:url];    
}

- (IBAction)buttonZone2Touched:(id)sender {
#pragma warning todo
}

- (IBAction)buttonZone3Touched:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://www.google.fr"];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)buttonZone4Touched:(id)sender {
    NSURL *url = [[NSBundle mainBundle]
                  URLForResource: @"demo2" withExtension:@"mp4"];
    [self launchVideoWithURL:url];
    
}

- (IBAction)buttonZone5Touched:(id)sender {
    NSURL *url = [[NSBundle mainBundle]
                  URLForResource: @"demo" withExtension:@"mp4"];
    [self launchVideoWithURL:url];
}

- (IBAction)buttonZone6Touched:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"demo2" ofType:@"mp4"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    [self launchVideoWithURL:url];
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
