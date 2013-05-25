//
//  VIDViewController.h
//  Video360
//
//  Created by Jean-Baptiste Rieu on 08/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
@class VIDVideoPlayerViewController;

@interface VIDGlkViewController : GLKViewController<UIGestureRecognizerDelegate>

@property (strong, nonatomic, readwrite) VIDVideoPlayerViewController* videoPlayerController;

@end
