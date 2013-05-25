//
//  VIDVideoPlayerViewController.m
//  Video360
//
//  Created by Jean-Baptiste Rieu on 24/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import "VIDVideoPlayerViewController.h"
#import "VIDGlkViewController.h"

#define ONE_FRAME_DURATION 0.03

#define HIDE_CONTROL_DELAY 5.0f
#define DEFAULT_VIEW_ALPHA 0.6f

/* AVPlayer keys */
NSString * const kRateKey			= @"rate";
NSString * const kCurrentItemKey	= @"currentItem";

static void *AVPlayerDemoPlaybackViewControllerRateObservationContext = &AVPlayerDemoPlaybackViewControllerRateObservationContext;
static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;

static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

@interface VIDVideoPlayerViewController ()
{
    VIDGlkViewController *_glkViewController;
    AVPlayerItemVideoOutput* _videoOutput;
    AVPlayer* _player;
    AVPlayerItem* _playerItem;
    dispatch_queue_t _myVideoOutputQueue;
	id _notificationToken;
    id _timeObserver;
    
    float mRestoreAfterScrubbingRate;
	BOOL seekToZeroBeforePlay;
    
    
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
                
                /* When the player item has played to its end time we'll toggle
                 the movie controller Pause button to be the Play button */
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:_playerItem];
                
                seekToZeroBeforePlay = NO;
                
                [_player addObserver:self
                              forKeyPath:kCurrentItemKey
                                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                 context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
                
                [_player addObserver:self
                              forKeyPath:kRateKey
                                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                 context:AVPlayerDemoPlaybackViewControllerRateObservationContext];            
                
                
                [_progressSlider setValue:0.0];
                
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
    _glkViewController = [[VIDGlkViewController alloc] init];
    
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
    
    [self updatePlayButton];
}

- (IBAction)playButtonTouched:(id)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if([self isPlaying]){
        [self pause];
    }else{
        [self play];
    }
}

- (void) updatePlayButton
{
    
    [_playButton setImage:[UIImage imageNamed:[self isPlaying] ? @"playback_pause" : @"playback_play"]
                 forState:UIControlStateNormal];
}

-(void) play
{
    if ([self isPlaying])
        return;
    /* If we are at the end of the movie, we must seek to the beginning first
     before starting playback. */
	if (YES == seekToZeroBeforePlay)
	{
		seekToZeroBeforePlay = NO;
		[_player seekToTime:kCMTimeZero];
	}
    
    [self updatePlayButton];
    [_player play];
    
    [self scheduleHideControls];
}

- (void) pause
{
    if (![self isPlaying])
        return;
    
    [self updatePlayButton];
    [_player pause];
    
    [self scheduleHideControls];
}

#pragma mark progress slider management
-(void) configureProgressSlider
{
    _progressSlider.center = CGPointMake(_playerControlBackgroundView.bounds.size.width * 0.5, _playerControlBackgroundView.bounds.size.height - 20.0);
    _progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _progressSlider.continuous = NO;
    _progressSlider.value = 0;
    
    [self initScrubberTimer];
	
	[self syncScrubber];
    
}

#pragma mark controls management
-(void)configureControleBackgroundView
{
    CGFloat parentWidth = self.view.bounds.size.width;
    CGFloat parentHeight = self.view.bounds.size.height;
    
    CGFloat width  = parentWidth /3 ;
    CGFloat height = parentHeight / 8;
    
    CGFloat x = parentWidth / 2 - width / 2 ;
    CGFloat y = parentHeight - height ;
    
    _playerControlBackgroundView.frame = CGRectMake(x, y, width, height);
}

-(void) toggleControls
{
    if(_playerControlBackgroundView.hidden){
        [self showControlsFast];
    }else{
        [self hideControlsFast];
    }
    
    
    [self scheduleHideControls];
}

-(void) scheduleHideControls
{
    if(!_playerControlBackgroundView.hidden)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(hideControlsSlowly) withObject:nil afterDelay:HIDE_CONTROL_DELAY];
    }
}

-(void) hideControlsWithDuration:(NSTimeInterval)duration
{
    _playerControlBackgroundView.alpha = DEFAULT_VIEW_ALPHA;
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^(void) {
                         
                         _playerControlBackgroundView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         if(finished)
                             _playerControlBackgroundView.hidden = YES;
                     }];
    
}

-(void) hideControlsFast
{
    [self hideControlsWithDuration:0.2];
}

-(void) hideControlsSlowly
{
    [self hideControlsWithDuration:1.0];
}

-(void) showControlsFast
{
    _playerControlBackgroundView.alpha = 0.0;
    _playerControlBackgroundView.hidden = NO;
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^(void) {
                         
                         _playerControlBackgroundView.alpha = DEFAULT_VIEW_ALPHA;
                     }
                     completion:nil];
}







- (void)removeTimeObserverFro_player
{
    if (_timeObserver)
    {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}


#pragma mark slider progress management
-(void)initScrubberTimer
{
	double interval = .1f;
	
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration))
	{
		return;
	}
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
		CGFloat width = CGRectGetWidth([_progressSlider bounds]);
		interval = 0.5f * duration / width;
	}
    

    __weak VIDVideoPlayerViewController* weakSelf = self;
	_timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                          queue:NULL /* If you pass NULL, the main queue is used. */
                                                     usingBlock:^(CMTime time)
                     {
                         [weakSelf syncScrubber];
                     }];
    
}



- (CMTime)playerItemDuration
{
	AVPlayerItem *playerItem = [_player currentItem];
	if (playerItem.status == AVPlayerItemStatusReadyToPlay)
	{
        /*
         NOTE:
         Because of the dynamic nature of HTTP Live Streaming Media, the best practice
         for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3.
         Prior to iOS 4.3, you would obtain the duration of a player item by fetching
         the value of the duration property of its associated AVAsset object. However,
         note that for HTTP Live Streaming Media the duration of a player item during
         any particular playback session may differ from the duration of its asset. For
         this reason a new key-value observable duration property has been defined on
         AVPlayerItem.
         
         See the AV Foundation Release Notes for iOS 4.3 for more information.
         */
        
		return([playerItem duration]);
	}
	
	return(kCMTimeInvalid);
}



- (void)syncScrubber
{
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration))
	{
		_progressSlider.minimumValue = 0.0;
		return;
	}
    
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
		float minValue = [_progressSlider minimumValue];
		float maxValue = [_progressSlider maximumValue];
		double time = CMTimeGetSeconds([_player currentTime]);
		
		[_progressSlider setValue:(maxValue - minValue) * time / duration + minValue];
	}
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (IBAction)beginScrubbing:(id)sender
{
	mRestoreAfterScrubbingRate = [_player rate];
	[_player setRate:0.f];
	
	/* Remove previous timer. */
	[self removeTimeObserverFro_player];
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender
{
	if ([sender isKindOfClass:[UISlider class]])
	{
		UISlider* slider = sender;
		
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration)) {
			return;
		}
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			float minValue = [slider minimumValue];
			float maxValue = [slider maximumValue];
			float value = [slider value];
			
			double time = duration * (value - minValue) / (maxValue - minValue);
			
			[_player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
		}
	}
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (IBAction)endScrubbing:(id)sender
{
	if (!_timeObserver)
	{
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration))
		{
			return;
		}
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			CGFloat width = CGRectGetWidth([_progressSlider bounds]);
			double tolerance = 0.5f * duration / width;
            
            __weak VIDVideoPlayerViewController* weakSelf = self;
			_timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:NULL usingBlock:
                             ^(CMTime time)
                             {
                                 [weakSelf syncScrubber];
                             }];
		}
	}
    
	if (mRestoreAfterScrubbingRate)
	{
		[_player setRate:mRestoreAfterScrubbingRate];
		mRestoreAfterScrubbingRate = 0.f;
	}
}

- (BOOL)isScrubbing
{
	return mRestoreAfterScrubbingRate != 0.f;
}

-(void)enableScrubber
{
    _progressSlider.enabled = YES;
}

-(void)disableScrubber
{
    _progressSlider.enabled = NO;
}

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
	
	/* AVPlayer "rate" property value observer. */
    if (context == AVPlayerDemoPlaybackViewControllerRateObservationContext)
	{
        [self updatePlayButton];
       // NSLog(@"AVPlayerDemoPlaybackViewControllerRateObservationContext");
	}
	/* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
	else if (context == AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext)
	{
       // NSLog(@"AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext");
	}
	else
	{
		[super observeValueForKeyPath:path ofObject:object change:change context:context];
	}
}

- (BOOL)isPlaying
{
	return mRestoreAfterScrubbingRate != 0.f || [_player rate] != 0.f;
}

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
	/* After the movie has played to its end time, seek back to time zero
     to play it again. */
	seekToZeroBeforePlay = YES;
}



@end
