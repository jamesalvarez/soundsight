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
    
    UIColor* bgColor = [UIColor whiteColor];
    UIColor* borderColor = [UIColor darkGrayColor];
    UIColor* shadow = [UIColor grayColor];
    // border radius
    [self.frameView.layer setCornerRadius:20.0f];
    
    [self.frameView.layer setBackgroundColor:bgColor.CGColor];
    [self.frameView.layer setBorderColor:borderColor.CGColor];
    //[self.frameView.layer setBorderWidth:1.0f];
    [self.frameView.layer setShadowColor:shadow.CGColor];
    [self.frameView.layer setShadowOffset:CGSizeMake(0, 2)];
    [self.frameView.layer setShadowRadius:2];
    [self.frameView.layer setShadowOpacity:1];
    [self.frameView.layer setMasksToBounds:NO];
    //[self.frameView.layer setShadowPath:
    
    /*
     
    cell.layer.shadowColor = UIColor.gray.cgColor
    cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)//CGSizeMake(0, 2.0);
    cell.layer.shadowRadius = 2.0
    cell.layer.shadowOpacity = 1.0
    cell.layer.masksToBounds = false
    cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius:cell.contentView.layer.cornerRadius).cgPath*/
    
}

- (void)setColor:(UIColor*)color {
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    [circleLayer setStrokeColor:[color CGColor]];
    [circleLayer setFillColor:[color CGColor]];
    CGFloat viewSize = self.iconImageView.frame.size.width - 2;
    [circleLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(1, 1, viewSize, viewSize)] CGPath]];
    for (CALayer *layer in [[self.iconImageView layer].sublayers copy]) {
        [layer removeFromSuperlayer];
    }
    [[self.iconImageView layer] addSublayer:circleLayer];
}


@end
