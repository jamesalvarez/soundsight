//
//  ConfigTableViewCell.m
//  Synestheatre
//
//  Created by James on 30/08/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import "ConfigCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+ExtraColours.h"

@implementation ConfigCell

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    [self.frameView.layer setCornerRadius:20.0f];
    [self.frameView.layer setMasksToBounds:NO];
}

- (void)setColor:(UIColor*)color {
    [self.frameView.layer setBackgroundColor:color.CGColor];
    [self.frameView.layer setBorderColor:color.CGColor];
}


@end
