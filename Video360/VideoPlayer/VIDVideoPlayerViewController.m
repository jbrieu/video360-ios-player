//
//  VIDVideoPlayerViewController.m
//  Video360
//
//  Created by Jean-Baptiste Rieu on 24/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import "VIDVideoPlayerViewController.h"
#import "VIDViewController.h"

#define ONE_FRAME_DURATION 0.03


static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

@interface VIDVideoPlayerViewController ()
{
    VIDViewController *_glkViewController;
    AVPlayerItemVideoOutput* _videoOutput;
    AVPlayer* _player;
    AVPlayerItem* _playerItem;
    dispatch_queue_t _myVideoOutputQueue;
	id _notificationToken;
    id _timeObserver;
    
    BOOL _playing;

}
@property (strong, nonatomic) IBOutlet UIView *playerControlBackgroundView;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UISlider *progressSlider;

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
    
    [self configurePlayButton];
    [self configureProgressSlider];
    [self configureControleBackgroundView];
    
    [self setupVideoPlayback];
 
    [self configureGLKView];
        
}

-(void)configureControleBackgroundView
{
    CGFloat parentWidth = self.view.bounds.size.width;
    CGFloat parentHeight = self.view.bounds.size.height;
    
    CGFloat width  = parentWidth /3 ;
    CGFloat height = parentHeight / 7;
    
    CGFloat x = parentWidth / 2 - width / 2 ;
    CGFloat y = parentHeight - height ;
    
    _playerControlBackgroundView.frame = CGRectMake(x, y, width, height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setPlayerControlBackgroundView:nil];
    [self setPlayButton:nil];
    [self setProgressSlider:nil];
    [super viewDidUnload];
}

#pragma mark video communication

- (CVPixelBufferRef) retrievePixelBufferToDraw
{
    CVPixelBufferRef pixelBuffer = [_videoOutput copyPixelBufferForItemTime:[_playerItem currentTime] itemTimeForDisplay:nil];
    
    return pixelBuffer;
}

#pragma mark video setting
#warning TODO : porter sur iOS5

-(void)setupVideoPlayback
{
    
	NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
	_videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
	_myVideoOutputQueue = dispatch_queue_create("myVideoOutputQueue", DISPATCH_QUEUE_SERIAL);
	[_videoOutput setDelegate:self queue:_myVideoOutputQueue];
    
    _player = [[AVPlayer alloc] init];
    
    NSURL *url = [[NSBundle mainBundle]
                  URLForResource: @"demo" withExtension:@"mp4"];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    [asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler:^{
        
        NSError* error = nil;
        AVKeyValueStatus status = [asset statusOfValueForKey:@"tracks" error:&error];
        if (status == AVKeyValueStatusLoaded)
        {
            _playerItem = [AVPlayerItem playerItemWithAsset:asset];            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_playerItem addOutput:_videoOutput];
                [_player replaceCurrentItemWithPlayerItem:_playerItem];
                [_videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];

            });
        }
        else
        {
            NSLog(@"%@ Failed to load the tracks.", self);
        }
    }];
}

#pragma mark rendering glk view management
-(void)configureGLKView
{
    _glkViewController = [[VIDViewController alloc] init];
    
    _glkViewController.videoPlayerController = self;
    
    [self.view insertSubview:_glkViewController.view belowSubview:_playerControlBackgroundView];
    [self addChildViewController:_glkViewController];
    [_glkViewController didMoveToParentViewController:self];
    
    _glkViewController.view.frame = self.view.bounds;
}


#pragma mark play button management
-(void)configurePlayButton
{
    _playButton.frame = CGRectMake(_playerControlBackgroundView.bounds.size.width * 0.5 - 20, 10, 40, 40);
    _playButton.backgroundColor = [UIColor clearColor];
    _playButton.showsTouchWhenHighlighted = YES;

    _playing = NO;
    [self updatePlayButton];
}

- (IBAction)playButtonTouched:(id)sender {
    if(_playing){
        [self pause];
    }else{
        [self play];
    }
}

- (void) updatePlayButton
{

    [_playButton setImage:[UIImage imageNamed:_playing ? @"playback_pause" : @"playback_play"]
                 forState:UIControlStateNormal];
}

-(void) play
{
    if (_playing)
        return;
    
    _playing = YES;
    [self updatePlayButton];
    [_player play];
}

- (void) pause
{
    if (!_playing)
        return;
    
    _playing = NO;
    [self updatePlayButton];
    [_player pause];
}

#pragma mark progress slider management
-(void) configureProgressSlider
{
    _progressSlider.center = CGPointMake(_playerControlBackgroundView.bounds.size.width * 0.5, _playerControlBackgroundView.bounds.size.height - 20.0);
    _progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _progressSlider.continuous = NO;
    _progressSlider.value = 0;

}


#pragma mark video observing
- (void)stopLoadingAnimationAndHandleError:(NSError *)error
{
	if (error) {
        NSString *cancelButtonTitle = NSLocalizedString(@"OK", @"Cancel button title for animation load error");
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason] delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
		[alertView show];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == AVPlayerItemStatusContext) {
		AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
		switch (status) {
			case AVPlayerItemStatusUnknown:
				break;
			case AVPlayerItemStatusReadyToPlay:
                // TODO Show button
				break;
			case AVPlayerItemStatusFailed:
				[self stopLoadingAnimationAndHandleError:[[_player currentItem] error]];
				break;
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)addDidPlayToEndTimeNotificationForPlayerItem:(AVPlayerItem *)item
{
	if (_notificationToken)
		_notificationToken = nil;
	
	_player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
	_notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:item queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		[[_player currentItem] seekToTime:kCMTimeZero];
	}];
}

- (void)syncTimeLabel
{
	double seconds = CMTimeGetSeconds([_player currentTime]);
	if (!isfinite(seconds)) {
		seconds = 0;
	}
	
	int secondsInt = round(seconds);
	int minutes = secondsInt/60;
	secondsInt -= minutes*60;
	
//	self.currentTime.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
//	self.currentTime.textAlignment = NSTextAlignmentCenter;
//    
//	self.currentTime.text = [NSString stringWithFormat:@"%.2i:%.2i", minutes, secondsInt];
}

- (void)addTimeObserverToPlayer
{
	/*
	 Adds a time observer to the player to periodically refresh the time label to reflect current time.
	 */
    if (_timeObserver)
        return;
    /*
     Use __weak reference to self to ensure that a strong reference cycle is not formed between the view controller, player and notification block.
     */
    __weak VIDVideoPlayerViewController* weakSelf = self;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 10) queue:dispatch_get_main_queue() usingBlock:
                     ^(CMTime time) {
                         [weakSelf syncTimeLabel];
                     }];
}

- (void)removeTimeObserverFromPlayer
{
    if (_timeObserver)
    {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}



@end
