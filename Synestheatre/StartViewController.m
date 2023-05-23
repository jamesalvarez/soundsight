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
    
    
    
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [AppDelegate restrictOrientation];
}

-(bool)hasADepthCam {
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                         discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTrueDepthCamera, AVCaptureDeviceTypeBuiltInTelephotoCamera, AVCaptureDeviceTypeBuiltInUltraWideCamera, AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInTripleCamera]
                                                         mediaType:AVMediaTypeVideo
                                                         position:AVCaptureDevicePositionUnspecified];

    NSArray *devices = discoverySession.devices;

    BOOL hasLiDAR = NO;
    BOOL hasDualCamera = NO;

    for (AVCaptureDevice *device in devices) {
        if ([device.deviceType isEqualToString:AVCaptureDeviceTypeBuiltInLiDARDepthCamera]) {
            hasLiDAR = YES;
        } else if ([device.deviceType isEqualToString:AVCaptureDeviceTypeBuiltInDualCamera]) {
            hasDualCamera = YES;
        } else if ([device.deviceType isEqualToString:AVCaptureDeviceTypeBuiltInTripleCamera]) {
            hasDualCamera = YES;
            hasLiDAR = YES;
        }
    }

    if (hasLiDAR) {
        NSLog(@"This device has a LiDAR camera");
    }

    if (hasDualCamera) {
        NSLog(@"This device has a dual camera");
    }

    return hasLiDAR || hasDualCamera;

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self navigationController] setNavigationBarHidden:true];
    static bool SHOWEDDISCLAIMER = false;


    

    
    // Do setup in bg and display spinner whilst it happens    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:@"Loading..." preferredStyle:UIAlertControllerStyleAlert];
    
    UIActivityIndicatorView* loadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(10, 5, 50, 50)];
    [loadingIndicator setHidesWhenStopped:true];
    [loadingIndicator startAnimating];
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleMedium;
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
                self->_selectModeLabel.text = @"SoundSight";
                [self dismissViewControllerAnimated:false completion:nil];
                [self->_collectionView reloadData];
                
                if (!SHOWEDDISCLAIMER) {
                    [self showDisclaimerDialog];
                    SHOWEDDISCLAIMER = true;
                }
            });
        });
        
    }];
    
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {}

// Called when leaving the main settings window
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    if ([segue.identifier  isEqual: @"modeStart"]) {
        // User has selected start on the mode dialog
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier: @"startShow" sender: self ];
        });
    } else {
        // User clicked back and does not want to start
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
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

- (IBAction)restorePurchasesTouch:(id)sender {

    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (IBAction)startButtonTouch:(id)sender {
    NSLog(@"start");
}

- (void)showDisclaimerDialog {

    NSString* message = @"Soundsight is not a substitute for other assistive devices or mobility aids and you need to exercise your own good judgment as to when to use it.  We recommend using bone-conducting headphones so that the Soundsight augments rather than blocks natural hearing.";

    if (![self hasADepthCam]) {
        message = @"WARNING: The device does not have a depth camera, and will not function correctly!  Soundsight is not a substitute for other assistive devices or mobility aids and you need to exercise your own good judgment as to when to use it.  We recommend using bone-conducting headphones so that the Soundsight augments rather than blocks natural hearing.";
    }

    UIAlertController* alert = [UIAlertController
          alertControllerWithTitle:@"Disclaimer"
          message: message
          preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction
          actionWithTitle:@"Understood" style:UIAlertActionStyleDefault
         handler:^(UIAlertAction * action) {}];

    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}


@end
