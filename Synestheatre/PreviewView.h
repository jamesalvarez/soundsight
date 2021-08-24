//
//  PreviewView.h
//  Synestheatre
//
//  Created by James on 27/09/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>

@class SynestheatreMain;

NS_ASSUME_NONNULL_BEGIN

@interface PreviewView : UIView

- (AVCaptureVideoPreviewLayer*)videoPreviewLayer;

- (void)update;
- (void)setSession:(AVCaptureSession*)session;
- (void)setSynestheatre:(SynestheatreMain*)synestheatreMain;
@end

NS_ASSUME_NONNULL_END
