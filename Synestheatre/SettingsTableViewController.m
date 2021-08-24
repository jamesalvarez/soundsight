//
//  SettingsTableViewController.m
//  Synestheatre
//
//  Created by James on 10/07/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import "SettingsTableViewController.h"

@implementation SettingsTableViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setShowCreditsFooter:NO];
    }
    return self;
}
@end
