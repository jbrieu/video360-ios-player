//
//  VIDGenericMenuViewController.m
//  Video360
//
//  Created by Jean-Baptiste Rieu on 28/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import "VIDGenericMenuViewController.h"
#import "VIDVideoPlayerViewController.h"
#import "VIDMenu2ViewController.h"

#define DIAPORAMA_DELAY 1.0 // delay between slide image in seconds

@interface VIDGenericMenuViewController ()
{
    int _currentImage;
}

@end

@implementation VIDGenericMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _currentImage = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if([_imageNames count]>0){
       [_backgroundImage setImage:[UIImage imageNamed:_imageNames[_currentImage]]];
        
        [NSTimer scheduledTimerWithTimeInterval:DIAPORAMA_DELAY target:self selector:@selector(updateBackground) userInfo:nil repeats:YES];
    }else{
        NSLog(@"You forgot to set background image(s)", nil);
    }
    
    
}

- (void)viewDidUnload {
    [self setBackgroundImage:nil];
    [super viewDidUnload];
}


#pragma mark  background management
-(void) updateBackground
{
    if([_imageNames count]>0){
        _currentImage++;
        if (_currentImage>[_imageNames count]-1)
        {
            _currentImage = 0;
        }
        
        [self.backgroundImage setImage:[UIImage imageNamed:_imageNames[_currentImage]]];
    }
}

#pragma mark launch actions
-(void) launchVideoWithName:(NSString*)name;
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"mp4"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    VIDVideoPlayerViewController *videoController = [[VIDVideoPlayerViewController alloc] initWithNibName:@"VIDVideoPlayerViewController" bundle:nil url:url];
    
    if(![[self presentedViewController] isBeingDismissed])
    {
        [self presentViewController:videoController animated:YES completion:nil];
    }
}

-(void) openURLWithString:(NSString*)stringurl
{
    NSURL *url = [NSURL URLWithString:stringurl];
    [[UIApplication sharedApplication] openURL:url];

}

@end
