//
//  AppDelegate.m
//  Synestheatre
//
//  Created by James on 23/09/2016.
//  Copyright © 2016 James. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "CameraManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Prevent app being launched in the background
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        NSLog(@"iOS launched %@ in the background. This app is not designed to be launched in the background, so it will exit peacefully.",
              [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]
              );
        
        exit(0);
    }
    
    // Prevent dimming
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [CameraManager queryCameraAuthorizationStatusAndNotifyUserIfNotGranted];
    
    // Set default orientation to portrait
    _currentOrientation = UIInterfaceOrientationPortrait;
    
    return YES;
}


- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    
    if(!self.restrictRotation)
        return UIInterfaceOrientationMaskAll;
    else if (_currentOrientation == UIInterfaceOrientationPortrait)
        return UIInterfaceOrientationMaskPortrait;
    else
        return UIInterfaceOrientationMaskLandscape;
}

+ (void)forceOrientation:(UIInterfaceOrientation)orientation {
    
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    appDelegate.currentOrientation = orientation;
    appDelegate.restrictRotation = true;
    [[UIDevice currentDevice]setValue:[NSNumber numberWithInteger:orientation]forKey:@"orientation"];
    [UINavigationController attemptRotationToDeviceOrientation];
}

+(void)restrictOrientation {
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [AppDelegate forceOrientation:appDelegate.currentOrientation];
}

+(void)unRestrictOrientation {
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    appDelegate.restrictRotation = false;
    [UINavigationController attemptRotationToDeviceOrientation];
}

@end
