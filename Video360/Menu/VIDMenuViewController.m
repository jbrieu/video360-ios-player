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
@property (strong, nonatomic) IBOutlet UIButton *buttonZone4;

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
    [self setButtonZone4:nil];
    [super viewDidUnload];
}

#pragma mark button management

- (IBAction)buttonZone4Touched:(id)sender {
    NSURL *url = [[NSBundle mainBundle]
                  URLForResource: @"demo" withExtension:@"mp4"];
    [self launchVideoWithURL:url];
    
}

#pragma mark launch actions
-(void) launchVideoWithURL:(NSURL*)url
{
    VIDVideoPlayerViewController *videoController = [[VIDVideoPlayerViewController alloc] initWithNibName:@"VIDVideoPlayerViewController" bundle:nil];
    videoController.videoURL = url;
    
    [self presentModalViewController:videoController animated:YES];
}

@end
