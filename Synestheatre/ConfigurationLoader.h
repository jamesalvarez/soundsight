//
//  ConfigurationLoader.h
//  Synestheatre
//
//  Created by James on 23/09/2016.
//  Copyright © 2016 James. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Configuration.h"
/**
 *  'ConfigurationLoader' deals with users custom configurations, loaded via iTunes
 *  When constructed it will copy the internal 'banjo' preset to the documents directory, if not there,
 *  and load all the configurations.  One is selected, and you can cycle through the others.
 *
 *  Configurations are JSON files in documents directory - very simple at the moment - see banjo.synt
 *  The 'name' key should correspond to a diretory name which contains the numbered sound files.
 *
 */

@interface ConfigurationLoader : NSObject

@property (nonatomic,readonly) NSArray* configNames;
@property (nonatomic,readonly) NSString* currentConfig;

/**
 *  Cycle to the next config
 */
-(NSString*)cycleConfig;

/**
 *  Obtain the current configuration
 */
-(Configuration*)loadConfigurationError:(NSError**)error;



@end
