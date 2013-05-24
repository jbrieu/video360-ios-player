//
//  VIDVideoPlayerViewController.m
//  Video360
//
//  Created by Jean-Baptiste Rieu on 24/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import "VIDVideoPlayerViewController.h"
#import "VIDViewController.h"

@interface VIDVideoPlayerViewController ()
{
    VIDViewController *_glkViewController;
    __weak IBOutlet UISegmentedControl *testButton;
}

@end

@implementation VIDVideoPlayerViewController

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
 
    _glkViewController = [[VIDViewController alloc] init];

    [self.view insertSubview:_glkViewController.view belowSubview:testButton];
    [self addChildViewController:_glkViewController];
    [_glkViewController didMoveToParentViewController:self];
    
    _glkViewController.view.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    testButton = nil;
    [super viewDidUnload];
}
@end
