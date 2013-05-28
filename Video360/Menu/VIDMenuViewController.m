//
//  VIDMenuViewController.m
//  Video360
//
//  Created by Jean-Baptiste Rieu on 26/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import "VIDMenuViewController.h"

#import "VIDMenu2ViewController.h"

@interface VIDMenuViewController ()

@end

@implementation VIDMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.imageNames = @[@"menu01_A_ipad.png", @"menu01_B_ipad.png", @"menu01_C_ipad.png"];
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setBackgroundImage:nil];
    [super viewDidUnload];
}



#pragma mark button management
- (IBAction)buttonZone1Touched:(id)sender {
    NSURL *url = [[NSBundle mainBundle]
                  URLForResource: @"demo" withExtension:@"mp4"];
    [self launchVideoWithURL:url];
}

- (IBAction)buttonZone2Touched:(id)sender {
    VIDMenu2ViewController *menu2Controller = [[VIDMenu2ViewController alloc] initWithNibName:@"VIDMenu2ViewController" bundle:nil];
    
    if(![[self presentedViewController] isBeingDismissed])
    {
        [self presentViewController:menu2Controller animated:YES completion:nil];
    }
    
}



- (IBAction)buttonZone3Touched:(id)sender {
    [self openURLWithString:@"http://www.google.fr"];
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
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *pathInDocument = [NSString stringWithFormat:@"%@/demo2.mp4", basePath];
    if(![[NSFileManager defaultManager] fileExistsAtPath:pathInDocument]) {
        NSString *pathInBundle = [[NSBundle mainBundle] pathForResource:@"demo2" ofType:@"mp4"];
        NSError *anyError = nil;
        [[NSFileManager defaultManager] copyItemAtPath:pathInBundle toPath:pathInDocument error:&anyError];
    }
    
    
    NSURL *url = [[NSURL alloc] initFileURLWithPath:pathInDocument];
    
    [self launchVideoWithURL:url];
}





@end
