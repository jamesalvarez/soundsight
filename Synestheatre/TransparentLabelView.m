//
//  TransparentLabelView.m
//  Synestheatre
//
//  Created by James on 16/03/2017.
//  Copyright © 2017 James. All rights reserved.
//

#import "TransparentLabelView.h"

@implementation TransparentLabelView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.textAlignment = NSTextAlignmentCenter;
        self.userInteractionEnabled = FALSE;
        self.selectable = FALSE;
        self.textColor = [UIColor whiteColor];
    }
    return self;
}

/* Prevents selection, but also gestures coming through...
- (BOOL)canBecomeFirstResponder {
    return NO;
}
*/
@end
