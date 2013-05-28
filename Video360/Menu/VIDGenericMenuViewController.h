//
//  VIDGenericMenuViewController.h
//  Video360
//
//  Created by Jean-Baptiste Rieu on 28/05/13.
//  Copyright (c) 2013 Video360 Developper. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VIDGenericMenuViewController : UIViewController

@property (strong, nonatomic) NSArray* imageNames;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImage;


-(void) launchVideoWithName:(NSString*)url;
-(void) openURLWithString:(NSString*)stringurl;

@end
