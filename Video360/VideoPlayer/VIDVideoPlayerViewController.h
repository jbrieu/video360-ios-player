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
@property (strong, nonatomic) IBOutlet UIView *debugView;
@property (strong, nonatomic) IBOutlet UILabel *rollValueLabel;
@property (strong, nonatomic) IBOutlet UILabel *yawValueLabel;
@property (strong, nonatomic) IBOutlet UILabel *pitchValueLabel;
@property (strong, nonatomic) IBOutlet UILabel *orientationValueLabel;



-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil url:(NSURL*)url;

-(CVPixelBufferRef) retrievePixelBufferToDraw;
-(void) toggleControls;

@end
