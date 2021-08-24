//
//  Toast.m
//  Synestheatre
//
//  Created by James on 01/08/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import "Toast.h"

@implementation Toast

/** Displays a message in a UIAlert for a second */
+ (void)makeToast:(NSString*)msg {
    
    UIViewController* vc = [Toast topViewController];
    
    [vc dismissViewControllerAnimated:false completion:nil];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    alert.view.userInteractionEnabled = false;
    [vc presentViewController:alert animated:YES completion:nil];
    
    int duration = 1; // duration in seconds
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [vc dismissViewControllerAnimated:NO completion:nil];
    });

    
}
+ (UIViewController *)topViewController {
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

+ (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}
@end
