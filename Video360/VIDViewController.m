//
//  VIDViewController.m
//  Video360
//
//  Created by Jean-Baptiste Rieu on 08/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import "VIDViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

# define ONE_FRAME_DURATION 0.03

static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

@interface VIDViewController ()
{
	AVPlayer *_player;
    id _notificationToken;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (strong, nonatomic) AVPlayerItemVideoOutput *videoOutput;


- (void)tearDownGL;

@end

@implementation VIDViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    ///////////PLAYER/////////////
    _player = [[AVPlayer alloc] init];
    
    
    
    /////////GL VIEW/////////////
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.delegate = self;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    self.preferredFramesPerSecond = 30;
    
    self.effect = [[GLKBaseEffect alloc] init];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    
}

- (void)viewWillAppear:(BOOL)animated
{
	[self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:AVPlayerItemStatusContext];
    
    [_player pause];
	    
    NSURL *url = [[NSBundle mainBundle]
                  URLForResource: @"demo" withExtension:@"mp4"];
    
	[self setupPlaybackForURL:url];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self removeObserver:self forKeyPath:@"player.currentItem.status" context:AVPlayerItemStatusContext];
	
	if (_notificationToken) {
		[[NSNotificationCenter defaultCenter] removeObserver:_notificationToken name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
		_notificationToken = nil;
	}
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
    
    // Dispose of any resources that can be recreated.
}


- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribColor);
    
    self.effect = nil;
}


#pragma mark - Playback setup

- (void)setupPlaybackForURL:(NSURL *)URL
{
	/*
	 Sets up player item and adds video output to it.
	 The tracks property of an asset is loaded via asynchronous key value loading, to access the preferred transform of a video track used to orientate the video while rendering.
	 After adding the video output, we request a notification of media change in order to restart the CADisplayLink.
	 */
	
	// Remove video output from old item, if any.
//	[[_player currentItem] removeOutput:self.videoOutput];
    
	AVPlayerItem *item = [AVPlayerItem playerItemWithURL:URL];
	AVAsset *asset = [item asset];
	
	[asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        
		if ([asset statusOfValueForKey:@"tracks" error:nil] == AVKeyValueStatusLoaded) {
			NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
			if ([tracks count] > 0) {
                NSError* error = nil;
                AVKeyValueStatus status = [asset statusOfValueForKey:@"tracks" error:&error];
                if (status == AVKeyValueStatusLoaded)
                {
                    NSDictionary* settings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] };
                    self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:settings];
                    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:asset];
                    [playerItem addOutput:self.videoOutput];
                    _player = [AVPlayer playerWithPlayerItem:playerItem];
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
                        [_player play];
                    });
                    
                }
                else
                {
                    NSLog(@"%@ Failed to load the tracks.", self);
                }
            }
        }
        
    }];
    
}

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
                //				self.playerView.presentationRect = [[_player currentItem] presentationSize];
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
    
    /*
     Setting actionAtItemEnd to None prevents the movie from getting paused at item end. A very simplistic, and not gapless, looped playback.
     */
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    _notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:item queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        // Simple item playback rewind.
        [[_player currentItem] seekToTime:kCMTimeZero];
    }];
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    
    GLKMatrix4 modelview = GLKMatrix4MakeTranslation(0, 0, -3.0f);
    self.effect.transform.modelviewMatrix = modelview;
    
    //    GLfloat ratio = self.view.bounds.size.width/self.view.bounds.size.height;
    //    GLKMatrix4 projection = GLKMatrix4MakePerspective(45.0f, ratio, 0.1f, 20.0f);
    //    self.effect.transform.projectionMatrix = projection;
    
    GLKMatrix4 ortho = GLKMatrix4MakeOrtho(0, 1.0f, 0, 1.0f, 0.1f, 20.0f);
    self.effect.transform.projectionMatrix = ortho;
    
    //    /*
    //	 The callback gets called once every Vsync.
    //	 Using the display link's timestamp and duration we can compute the next time the screen will be refreshed, and copy the pixel buffer for that time
    //	 This pixel buffer can then be processed and later rendered on screen.
    //	 */
    //	CMTime outputItemTime = kCMTimeInvalid;
    //
    //	// Calculate the nextVsync time which is when the screen will be refreshed next.
    //	CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);
    //
    //	outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
    //
    //	if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime]) {
    //		CVPixelBufferRef pixelBuffer = NULL;
    //		pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
    //
    //		[[self view] displayPixelBuffer:pixelBuffer];
    //	}
    //
    
    
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self.effect prepareToDraw];
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f, 1,
        1.0f, -1.0f, 1,
        -1.0f,  1.0f, 1,
        1.0f,  1.0f, 1
    };
    
    static const GLubyte squareColors[] = {
        255, 255,   0, 255,
        0,   255, 255, 255,
        0,     0,   0,   0,
        255,   0, 255, 255,
    };
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, squareVertices);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, squareColors);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribColor);
    
    //TODO : mettre ici le contenu de la APEAGLView de l'autre appli
    
}




#pragma mark - AVPlayerItemOutputPullDelegate

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
    // Restart display link.
    //	[[self displayLink] setPaused:NO];
}


@end
