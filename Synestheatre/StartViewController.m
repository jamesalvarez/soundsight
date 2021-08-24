//
//  StartViewController.m
//  Synestheatre
//
//  Created by James on 28/07/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import "StartViewController.h"
#import "ConfigurationManager.h"
#import "ConfigCell.h"
#import "AppDelegate.h"
#import "InAppPurchaseManager.h"

@interface StartViewController () {
    ConfigurationManager*  _configurationManager;
}

@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _selectModeLabel.text = @"";
    // Load background image
    //int imageN = arc4random_uniform(8) + 1;
   // UIImageView* bgView = (UIImageView*)self.view;
    
    //[bgView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"art%d",imageN]]];
    
    // Notification needs to be observed before configurtaiton manager starts
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCollectionView) name:IAPHelperNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showErrorDialog) name:IAPHelperErrorNotification object:nil];
    
    _collectionView.layer.borderWidth = 1.0;
    if (_configurationManager == nil) {
        _configurationManager = [ConfigurationManager sharedInstance];
    }
    
    [_collectionView setOpaque:NO];
    [_collectionView setBackgroundColor:[UIColor clearColor]];
    _collectionView.layer.borderWidth = 0.0;
    [_collectionView setDataSource:_configurationManager];
    [_collectionView setDelegate:self];
    [_collectionView reloadData];
    
    // Do setup in bg and display spinner whilst it happens
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:@"Loading configurations..." preferredStyle:UIAlertControllerStyleAlert];
    
    UIActivityIndicatorView* loadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(10, 5, 50, 50)];
    [loadingIndicator setHidesWhenStopped:true];
    [loadingIndicator startAnimating];
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [alert.view addSubview:loadingIndicator];

    [self presentViewController:alert animated:true completion:^{
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        dispatch_async(queue, ^{
            // Perform async operation
            [[ConfigurationManager sharedInstance] doSetup];
            dispatch_async(dispatch_get_main_queue(), ^{
                // Update UI
                [[InAppPurchaseManager sharedInstance ]requestProductsWithCompletionHandler:^void(BOOL success) {
                    [self->_configurationManager refreshLockedStatus];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self->_collectionView reloadData];
                    });
                }];
                self->_selectModeLabel.text = @"Select mode:";
                [self dismissViewControllerAnimated:false completion:nil];
                [self->_collectionView reloadData];
            });
        });
        
    }];
    
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"start view controller will appear");
    [AppDelegate unRestrictOrientation];
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    static bool SHOWEDDISCLAIMER = false;
    
    if (!SHOWEDDISCLAIMER) {
        [self showDisclaimerDialog];
        SHOWEDDISCLAIMER = true;
    }
    
}

-(void)showErrorDialog {

    
    UIAlertController* alert = [UIAlertController
          alertControllerWithTitle:@"Error with purchase"
          message:@"You must be connected to the internet and logged into the app-store."
          preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction
          actionWithTitle:@"OK" style:UIAlertActionStyleDefault
         handler:^(UIAlertAction * action) {}];

    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateCollectionView {
    NSLog(@"updateColelctionView");
    [_configurationManager refreshLockedStatus];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_collectionView reloadData];
    });
    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    
    Configuration* selectedConfig = ((ConfigCell*)sender).config;
    
    if (selectedConfig.locked) {
        
        //TRIGGER PURCHASING
        [[InAppPurchaseManager sharedInstance] buyProductWithIdentifer:selectedConfig.productIdentifier];
        [_collectionView reloadData];
        return false;
    } else {
        [_configurationManager setCurrentConfig:selectedConfig];
        return true;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"prepare");
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [[_collectionView collectionViewLayout] invalidateLayout];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    CGFloat width  = collectionView.frame.size.width;
    
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
    {
         // code for landscape orientation
        return CGSizeMake((width * 0.5) - 20, 100);
    } else {
        return CGSizeMake(width - 20, 100);
    }
}

- (IBAction)aboutButtonTouch:(id)sender {
    
    // Show modal dialog with info
    [self showDisclaimerDialog];
}

- (void)showDisclaimerDialog {

    UIAlertController* alert = [UIAlertController
          alertControllerWithTitle:@"Disclaimer"
          message:@"Soundsight is not a substitute for other assistive devices or mobility aids and you need to exercise your own good judgment as to when to use it.  We recommend using bone-conducting headphones so that the Soundsight augments rather than blocks natural hearing."
          preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction
          actionWithTitle:@"Understood" style:UIAlertActionStyleDefault
         handler:^(UIAlertAction * action) {}];

    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}


@end
