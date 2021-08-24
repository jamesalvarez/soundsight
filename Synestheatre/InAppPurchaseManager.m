//
//  InAppPurchaseManager.m
//  Synestheatre
//
//  Created by James on 25/10/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import "InAppPurchaseManager.h"



@implementation InAppPurchaseManager

+ (InAppPurchaseManager *)sharedInstance {
    static dispatch_once_t once;
    static InAppPurchaseManager * sharedInstance;
    dispatch_once(&once, ^{
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"com.soundsight.colour_orchestra"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"com.soundsight.musical_shapes"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"com.soundsight.beach_chill"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"com.soundsight.string_pluck"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"com.soundsight.surrounding_nature"];
        
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      @"com.soundsight.skylarks",
                                      @"com.soundsight.scientifictones",
                                      nil];
        
        
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

    


@end
