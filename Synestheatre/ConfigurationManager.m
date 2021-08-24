//
//  ConfigurationManager.m
//  Synestheatre
//
//  Created by James on 23/09/2016.
//  Copyright © 2016 James. All rights reserved.
//

#import "ConfigurationManager.h"
#import "HRTFPreProcessor.h"
#import "SynestheatreMain.h"
#import "ConfigCell.h"
#import "UIColor+ExtraColours.h"
#import "InAppPurchaseManager.h"

@interface ConfigurationManager () {
    NSFileManager* _fileManager;
    NSString* _documentsDirectory;
    NSDictionary* _configPaths;
    bool _scanned;
}

@end

@implementation ConfigurationManager

+ (ConfigurationManager *)sharedInstance {
    static dispatch_once_t once;
    static ConfigurationManager * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(id)init {
    if ( !(self = [super init])) return nil;
    _scanned = false;
    return self;
}

-(void)doSetup {
    _fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _documentsDirectory = [paths objectAtIndex:0];
    
    [self copyDefaultConfigurationsIfNotPresent];
    [self scanForConfigs];
    _scanned = true;
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
 * Search documents directory for synt files.  Loads the configs.
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
    NSArray* configNames = [cfPaths allKeys];
    NSMutableArray* newConfigs = [[NSMutableArray alloc] init];
    NSString* selectedConfig = [[NSUserDefaults standardUserDefaults] objectForKey:@"synt_name"];
    _currentConfig = nil;
    
    for (int i = 0; i < [configNames count]; i += 1) {
        NSString* configPath = _configPaths[configNames[i]];
        
        Configuration* configuration = [[Configuration alloc] init];
        NSError* error = nil;
        [configuration loadSyntFile:configPath error:&error];
        
        if (!error) {
            [newConfigs addObject:configuration];
        } else {
            NSLog(@"%@", error.description);
        }
        
        if ([selectedConfig isEqualToString:configuration.name]) {
            _currentConfig = configuration;
        }
        
    }
    
    _configs = newConfigs;

    bool thereAreConfigs = ([newConfigs count] > 0);
    if (thereAreConfigs && _currentConfig == nil) {
        _currentConfig = _configs[0];
        [[NSUserDefaults standardUserDefaults] setObject: _currentConfig.name forKey:@"synt_name"];
    }
    
    
    return thereAreConfigs;
}

-(void) setCurrentConfig:(Configuration*)config {
    [[NSUserDefaults standardUserDefaults] setObject: config.name forKey:@"synt_name"];
    _currentConfig = config;
}

-(void) refreshLockedStatus {
    for (int i = 0; i < [_configs count]; i += 1) {
        Configuration* config = (Configuration*)_configs[i];
        NSString* pid = config.productIdentifier;
        config.locked = ![[NSUserDefaults standardUserDefaults] boolForKey:pid];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_configs count];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    
    ConfigCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"config" forIndexPath:indexPath];
    
    Configuration* config = _configs[indexPath.row];
    
    [cell setConfig:config];
    [cell.nameLabel setText: config.name];
    [cell.descriptionLabel setText: config.shortDescriptionText];
    
    [cell setColor:[UIColor patchColor:(int)indexPath.row]];
    if (config.locked) {
        [cell.statusView setImage: [UIImage imageNamed:@"baseline_lock_black_36pt"]];
    } else {
        [cell.statusView setImage:nil];
    }
    return cell;
}


#pragma mark -


@end
