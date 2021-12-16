//
//  ConfigurationLoader.m
//  Synestheatre
//
//  Created by James on 23/09/2016.
//  Copyright © 2016 James. All rights reserved.
//

#import "ConfigurationLoader.h"
#import "HRTFPreProcessor.h"
#import "SynestheatreMain.h"



@interface ConfigurationLoader () {
    NSFileManager* _fileManager;
    NSString* _documentsDirectory;
    NSDictionary* _configPaths;
}

@end

@implementation ConfigurationLoader

-(id)init {
    if ( !(self = [super init])) return nil;
    
    _fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _documentsDirectory = [paths objectAtIndex:0];
    
    [self copyDefaultConfigurationsIfNotPresent];
    
    if (![self scanForConfigs]) {
        return nil; // no configs present
    }
    
    
    
    return self;
}



-(NSString*)cycleConfig {
    //_currentConfigIndex = (_currentConfigIndex + 1) % [_configNames count];
    //_currentConfig = _configNames[_currentConfigIndex];
    return _currentConfig;
}

/*
 * Loads current configuration.  Outputs
 */
-(Configuration*)loadConfigurationError:(NSError**)error {
    
    *error = nil;
    
    NSString *defaultConfig = [[NSUserDefaults standardUserDefaults] stringForKey:@"synt_name"];
    
    if (defaultConfig && [_configNames containsObject:defaultConfig]) {
        _currentConfig = defaultConfig;
    } else {
        // Config name not found
        NSString* msg = [NSString stringWithFormat:@"Config named: %@ not found! Using default.", defaultConfig];
        [Toast makeToast:msg];
        _currentConfig = _configNames[0];
    }
    
    NSString* configPath = _configPaths[_currentConfig];
    
    Configuration* configuration = [[Configuration alloc] init];
    [configuration loadSyntFile:configPath error:error];

    if (*error != nil) {
        return nil;
    }
    return configuration;
}





/**
 * Copies bundled synt files and directories to documents path if they do
 * not exist there already
 */
-(void)copyDefaultConfigurationsIfNotPresent {
    
    NSArray *filePaths = [NSBundle pathsForResourcesOfType:@"synt" inDirectory:[[NSBundle mainBundle] bundlePath]];

    [filePaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *fullPath = (NSString *)obj;
        NSString *filename = [fullPath lastPathComponent];
        NSString *extension = [[filename pathExtension] lowercaseString];
        NSString *filenameNoExtension = [filename stringByDeletingPathExtension]; // doubles as directory name
        
        
        if ([extension isEqualToString:@"synt"]) {
        
            NSString *configFilePath = [self->_documentsDirectory stringByAppendingPathComponent: filename];

            if ([self->_fileManager fileExistsAtPath:configFilePath] == NO) {
                NSString *resourcePath = [[NSBundle mainBundle] pathForResource: filenameNoExtension ofType: extension];
                if (resourcePath)
                    [self->_fileManager copyItemAtPath:resourcePath toPath:configFilePath error:nil];
            }
            
            NSString *directoryPath = [self->_documentsDirectory stringByAppendingPathComponent: filenameNoExtension];
            
            if ([self->_fileManager fileExistsAtPath:directoryPath] == NO) {
                NSString *resourcePath = [[NSBundle mainBundle] pathForResource: filenameNoExtension ofType:@""];
                if (resourcePath)
                    [self->_fileManager copyItemAtPath:resourcePath toPath:directoryPath error:nil];
            }
            
            
        }
    }];

}

/**
 * Search documents directory for synt files.  Populates _configPaths and
 * _configNames for these files.
 */
-(bool)scanForConfigs {
    NSMutableDictionary* cfPaths = [[NSMutableDictionary alloc] init];
    NSArray* dirs = [_fileManager contentsOfDirectoryAtPath:_documentsDirectory error:nil];
    [dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *filename = (NSString *)obj;
        NSString *extension = [[filename pathExtension] lowercaseString];
        if ([extension isEqualToString:@"synt"]) {
            NSString* fullPath = [self->_documentsDirectory stringByAppendingPathComponent:filename];
            NSString* tag = [filename stringByDeletingPathExtension];
            [cfPaths setValue:fullPath forKey:tag];
        }
    }];
    
    _configPaths = cfPaths;
    _configNames = [cfPaths allKeys];
    return ([_configNames count] > 0);
}



@end
