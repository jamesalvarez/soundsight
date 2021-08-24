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
    // Prevent app being launched in the background when structure sensor is launched
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        NSLog(@"iOS launched %@ in the background. This app is not designed to be launched in the background, so it will exit peacefully.",
              [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]
              );
        
        exit(0);
    }
    
    // Set defaults
    [self registerDefaultsFromSettingsBundle];
    
    // Prevent dimming
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [CameraManager queryCameraAuthorizationStatusAndNotifyUserIfNotGranted];
    
    // Set default orientation to portrait
    _currentOrientation = UIInterfaceOrientationPortrait;
    
    return YES;
}


- (void)registerDefaultsFromSettingsBundle
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:[self defaultsFromPlistNamed:@"Root"]];
}

- (NSDictionary *)defaultsFromPlistNamed:(NSString *)plistName
{
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"InAppSettings" ofType:@"bundle"];
    NSString *plistFullName = [NSString stringWithFormat:@"%@.plist", plistName];
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:plistFullName]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    
    for (NSDictionary *prefSpecification in preferences)
    {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        id value = [prefSpecification objectForKey:@"DefaultValue"];
        
        if (key && value)
        {
            [defaults setObject:value forKey:key];
        }
        
        NSString *type = [prefSpecification objectForKey:@"Type"];
        
        if ([type isEqualToString:@"PSChildPaneSpecifier"])
        {
            NSString *file = [prefSpecification objectForKey:@"File"];
            [defaults addEntriesFromDictionary:[self defaultsFromPlistNamed:file]];
        }
    }
    
    return defaults;
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
