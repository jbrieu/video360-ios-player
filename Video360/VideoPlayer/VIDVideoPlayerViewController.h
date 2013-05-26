//
//  VIDVideoPlayerViewController.h
//  Video360
//
//  Created by Jean-Baptiste Rieu on 24/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VIDVideoPlayerViewController : UIViewController<AVPlayerItemOutputPullDelegate>

@property (strong, nonatomic) NSURL *videoURL;

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil url:(NSURL*)url;

-(CVPixelBufferRef) retrievePixelBufferToDraw;
-(void) toggleControls;

@end
