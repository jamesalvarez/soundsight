//
//  PasswordViewController.m
//  Synestheatre
//
//  Created by James on 09/08/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import "PasswordViewController.h"
#import "ConfigurationLoader.h"
#import "Toast.h"
#import "Sandboxer.h"

static NSDate *start;

@interface PasswordViewController () {
    ConfigurationLoader*  _configurationLoader;
    
}

@end

@implementation PasswordViewController

- (void)viewDidLoad {
    
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"sensor"] isEqualToString:@"file"]) {
        _loadFileButton.hidden = false;
        
        
        
    } else {
        _loadFileButton.hidden = true;
    }
    
    
    
    _configTableView.layer.borderWidth = 1.0;
    _configurationLoader = [[ConfigurationLoader alloc] init];
    [super viewDidLoad];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_configurationLoader.configNames count];
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"config"];
    [cell.textLabel setText:_configurationLoader.configNames[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    int row = (int)[_configurationLoader.configNames indexOfObject:_configurationLoader.currentConfig];
    bool selected = indexPath.row == row;
    if (selected) {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%ld", (long)indexPath.row);
    int row = (int)indexPath.row;
    
    if (row > -1) {
        NSString* selectedConfig = _configurationLoader.configNames[row];
        [[NSUserDefaults standardUserDefaults] setObject:selectedConfig forKey:@"synt_name"];
    }
}


- (void)checkPassword:(void (^)(bool))onSuccess;
{
    // If user has entered password 5 minutes ago, allow
    if (start != nil && [start timeIntervalSinceNow] > (-5 * 60)) {
        NSLog(@"%f",[start timeIntervalSinceNow]);
        onSuccess(true);
        return;
    }
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Password"
                                 message:@"Please enter password:"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Buttons
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Password";
        textField.textColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.secureTextEntry = YES;
    }];
    
    UIAlertAction* okButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    UITextField *textField = [alert.textFields firstObject];
                                    
                                    if ([[textField text] isEqualToString:@"f"]) {
                                        start = [NSDate date];
                                        onSuccess(true);
                                    } else {
                                        onSuccess(false);
                                    }
                                    
                                }];
    
    UIAlertAction* cancelButton = [UIAlertAction
                               actionWithTitle:@"Cancel"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   onSuccess(false);
                               }];
    
    [alert addAction:okButton];
    [alert addAction:cancelButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)passwordButtonPress:(id)sender {
    [self checkPassword: ^void (bool success) {
        if (success) {
            [self performSegueWithIdentifier:@"settings" sender:nil];
        } else {
            [self performSegueWithIdentifier:@"unwind" sender:nil];
            [Toast makeToast:@"Incorrect password"];
            
        }
    }];
    
}

- (IBAction)saveSyntFilePress:(UIButton *)sender {
    [self checkPassword: ^void (bool success) {
        if (success) {
            NSError* error;
            Configuration *configuration = [self->_configurationLoader loadConfigurationError:&error];
            
            if (error) {
                [Toast makeToast:[error localizedDescription]];
                return;
            } else {
                [configuration saveSyntFileWithCurrentSettings];
            }
            
            [self performSegueWithIdentifier:@"unwind" sender:nil];
            [Toast makeToast:@"Saved"];
        } else{
            [self performSegueWithIdentifier:@"unwind" sender:nil];
            [Toast makeToast:@"Incorrect password"];
        }
    }];
}

- (NSUInteger)currentSelectedRowIndex
{
    NSIndexPath *selectedIndexPath = [self.configTableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        return selectedIndexPath.row;
    }
    else {
        return NSNotFound;
    }
}

- (IBAction)restartEnginePress:(id)sender {
    [self performSegueWithIdentifier:@"unwind" sender:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"RestartEngine" object:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"settings"]) {
        IASKAppSettingsViewController *settingsViewController = (id)((UINavigationController*)segue.destinationViewController).topViewController;
        settingsViewController.delegate = self;
    }
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self performSegueWithIdentifier:@"unwind" sender:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RestartEngine" object:self];
    }];
    
}

- (IBAction)backButtonPress:(id)sender {
    [self performSegueWithIdentifier:@"unwind" sender:nil];
}

- (IBAction)loadFileButtonPress:(id)sender {
    [[Sandboxer shared] trigger];
}
@end
