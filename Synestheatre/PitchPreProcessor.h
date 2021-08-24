//
//  PitchPreProcessor.h
//  Synestheatre
//
//  Created by James on 11/07/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PitchPreProcessor : NSObject

+ (void)makePitchFilesFromSoundURL:(NSURL*)url pitches:(NSArray*)pitches outputDirectory:(NSString*)outputDirectory error:(NSError * _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
