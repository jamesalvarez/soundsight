//
//  UIColor+ExtraColours.m
//  
//
//  Created by James on 03/09/2019.
//

#import "UIColor+ExtraColours.h"

@implementation UIColor (ExtraColours)

+ (UIColor *)colorWithHueDegrees:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness {
    return [UIColor colorWithHue:(hue/360) saturation:saturation brightness:brightness alpha:1.0];
}

+ (UIColor *)lightestGreyColour {
    return [UIColor colorWithHueDegrees:0 saturation:0.0 brightness:0.9];
}

+ (UIColor *)patchColor:(int)index {
    
    float brightness = 0.7;
    
    switch (index) {
        case 0:
            return [UIColor colorWithHueDegrees:0 saturation:0.8 brightness:brightness];
        case 1:
            return [UIColor colorWithHueDegrees:45 saturation:0.8 brightness:brightness];
        case 2:
            return [UIColor colorWithHueDegrees:90 saturation:0.8 brightness:brightness];
        case 3:
            return [UIColor colorWithHueDegrees:135 saturation:0.8 brightness:brightness];
        case 4:
            return [UIColor colorWithHueDegrees:180 saturation:0.8 brightness:brightness];
        case 5:
            return [UIColor colorWithHueDegrees:215 saturation:0.8 brightness:brightness];
        default:
            return [UIColor colorWithHueDegrees:250 saturation:0.8 brightness:brightness];
    }
    
}


@end
