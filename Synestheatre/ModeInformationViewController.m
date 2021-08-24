//
//  ModeInformationViewController.m
//  Synestheatre
//
//  Created by James on 14/09/2020.
//  Copyright © 2020 James. All rights reserved.
//

#import "ModeInformationViewController.h"
#import "ConfigurationManager.h"

@interface ModeInformationViewController () {
    ConfigurationManager*  _configurationManager;
}

@end

@implementation ModeInformationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_configurationManager == nil) {
        _configurationManager = [ConfigurationManager sharedInstance];
    }
    
    [_titleLabel setText: _configurationManager.currentConfig.name];
    [_descriptionLabel setText:_configurationManager.currentConfig.descriptionText];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

// Called when leaving the main settings window
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {}

@end
