//
//  AppDelegate.h
//  Synestheatre
//
//  Created by James on 23/09/2016.
//  Copyright © 2016 James. All rights reserved.
//

#import <UIKit/UIKit.h>


@class MainViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property BOOL restrictRotation;
@property UIInterfaceOrientation currentOrientation;

+(void)forceOrientation:(UIInterfaceOrientation)orientation;
+(void)restrictOrientation;
+(void)unRestrictOrientation;

@end
