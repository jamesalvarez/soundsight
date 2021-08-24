//
//  ConfigurationManager.h
//  Synestheatre
//
//  Created by James on 23/09/2016.
//  Copyright © 2016 James. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Configuration.h"
/**
 *  'ConfigurationManager' deals with users custom configurations, loaded via iTunes
 *  When constructed it will copy the internal 'banjo' preset to the documents directory, if not there,
 *  and load all the configurations.  One is selected, and you can cycle through the others.
 *
 *  Configurations are JSON files in documents directory 
 *  The 'name' key should correspond to a diretory name which contains the numbered sound files.
 *
 */

@interface ConfigurationManager : NSObject <UICollectionViewDataSource>

@property (nonatomic,readonly) NSArray* configs;
@property (nonatomic,readonly) Configuration* currentConfig;

+ (ConfigurationManager *)sharedInstance;

-(void)doSetup;
-(void) setCurrentConfig:(Configuration*)config;
-(void) refreshLockedStatus;

@end
