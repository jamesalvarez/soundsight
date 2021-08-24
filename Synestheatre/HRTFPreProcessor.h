//
//  HRTFPreProcessor.h
//  Synestheatre
//
//  Created by James on 28/11/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HRTFPreProcessor : NSObject

+ (void)makeHRTFFilesFromSoundURL:(NSURL*)url angleDegrees:(int) angle points:(int)nPoints startIndex:(int)startIndex outputDirectory:(NSString*)outputDirectory error:(NSError * _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
