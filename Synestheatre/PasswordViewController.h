//
//  PasswordViewController.h
//  Synestheatre
//
//  Created by James on 09/08/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InAppSettingsKit/IASKAppSettingsViewController.h"

@interface PasswordViewController : UIViewController <IASKSettingsDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *configTableView;
@property (weak, nonatomic) IBOutlet UIButton *loadFileButton;

- (IBAction)passwordButtonPress:(id)sender;

- (IBAction)saveSyntFilePress:(UIButton *)sender;

- (IBAction)restartEnginePress:(id)sender;

- (IBAction)backButtonPress:(id)sender;

- (IBAction)loadFileButtonPress:(id)sender;
@end
