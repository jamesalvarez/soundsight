
#import "MainViewController.h"
#import "SynestheatreMain.h"
#import "SensorManager.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import "AppDelegate.h"

@interface MainViewController () {
    AVSpeechSynthesizer *_synthesizer;
    SensorManager* _sensorManager;
    AudioController* _audioController;
    id<DepthSensor> _depthSensor;
}
@end


@implementation MainViewController


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _sensorManager = [[SensorManager alloc] init];
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"main view controller will appear");
    [AppDelegate restrictOrientation];
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];
    NSLog(@"View Did Appear");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sensorChanged:)
                                                 name:EAAccessoryDidConnectNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sensorChanged:)
                                                 name:EAAccessoryDidDisconnectNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saySomething:)
                                                 name:@"SaySomething"
                                               object:nil];
    
    
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    
    [self restartEngine];
}




-(void) viewDidDisappear:(BOOL)animated {
    
    NSLog(@"View Did Disappear");
    [self stopEngine];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
}

-(void) sensorChanged:(NSNotification *) notification {
    NSLog(@"Sensor changed!");
    
    if (_synestheatreMain) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Clear views to reflect change
            [self restartEngine];
        });
    }
}
    
-(void) restartEngine {

    // Load a UI to show laoding
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:@"Please wait..." preferredStyle:UIAlertControllerStyleAlert];
    
    UIActivityIndicatorView* loadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(10, 5, 50, 50)];
    [loadingIndicator setHidesWhenStopped:true];
    [loadingIndicator startAnimating];
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleMedium;
    [alert.view addSubview:loadingIndicator];
    UIViewController* vc = [Toast topViewController];
    
    [vc presentViewController:alert animated:true completion:^{
        [self restartEngineWork];
        [vc dismissViewControllerAnimated:false completion:nil];
    }];
}

-(void) stopEngine {
    // This also stops the depth sensor
    if (_synestheatreMain != nil) {
        [_synestheatreMain stop];
        _synestheatreMain = nil;
    }
    
    _depthSensor = nil;
}
        
-(void) restartEngineWork {
    
    [self stopEngine];
    
    _depthSensor = [_sensorManager getSensor];
    [_depthSensor setPreviewView:_previewView];
    
    if (_audioController == nil) {
        _audioController = [[AudioController alloc] init];
        if (_audioController == nil) {
            [NSException raise:@"Audio controller could not be created" format:@"Audio controller could not be created"];
        }
    }

    // Initialize and start a new synestheatre
    _synestheatreMain = [[SynestheatreMain alloc] initWithAudioController:_audioController
                                                              depthSensor:_depthSensor];
    
    if (_synestheatreMain == nil) {
        [NSException raise:@"Synestheatre could not be created" format:@"Synestheatre could not be created"];
    }
    
    if (_synthesizer == nil) {
        _synthesizer = [[AVSpeechSynthesizer alloc] init];
    }
    
    [_previewView setSynestheatre:_synestheatreMain];
    
    
    // Setup parameter controller
    _parameterController.synestheatreMain = _synestheatreMain;
    
    // Block for updates when new depth data arrives
    MainViewController * __weak weakSelf = self;
    _depthSensor.newDataBlock = ^() {
        [weakSelf.synestheatreMain depthDataUpdated];
        [weakSelf.previewView update];
    };
    
    
    // Set orientation
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [_synestheatreMain setLandscapeMode: appDelegate.currentOrientation != UIInterfaceOrientationPortrait ];
    
    // Start synestheatre
    [_synestheatreMain start];
    
    // Config is set by start
    
}

// Called when leaving the main settings window
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {}


#pragma mark speech

-(void)saySomething:(NSNotification*)notification {
    [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    NSString *something = notification.object;
    //NSLog(@"Saying: %@", something);
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:something];
    [utterance setRate:0.4f];
    [_synthesizer speakUtterance:utterance];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"settings_show"]) {
        IASKAppSettingsViewController *settingsViewController = (id)((UINavigationController*)segue.destinationViewController).topViewController;
        settingsViewController.delegate = self;
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark IASKAppSettingsViewControllerDelegate protocol
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark image view


-(UIImage*) debugImage {
    NSArray* volumes = _synestheatreMain.volumes;
    int _cols = _synestheatreMain.config.cols;
    int _rows = _synestheatreMain.config.rows;
    int _colours = _synestheatreMain.config.colours;
    
    int multipler = 10;
    int m_cols = _cols * multipler;
    int m_rows = _rows * multipler;
    
    unsigned char transparency = 127;
    
    unsigned char pixelData[m_cols * m_rows * 4];
    
    for(int row = 0; row < m_rows; ++row) {
        for(int col = 0; col < m_cols; ++col) {
            
            int actualRow = floor(row / multipler);
            int actualCol = floor(col / multipler);
            
            float vol = 0;
            int colourOfPixel = -1;
            
            for(int colour = 0; colour < _colours; ++colour) {
                
                int index = colour + (actualCol * _colours) + (actualRow * _cols * _colours);
                
                NSNumber* volume = volumes[index];
                float floatVol = [volume floatValue];
                
                if (floatVol > vol) {
                    vol = floatVol;
                    colourOfPixel = colour;
                }
            }
            
            int pixelIndex = ((row * m_cols) + col) * 4;
            switch(colourOfPixel) {
                case -1:
                    pixelData[pixelIndex] = 0;
                    pixelData[pixelIndex + 1] = 0;
                    pixelData[pixelIndex + 2] = 0;
                    pixelData[pixelIndex + 3] = transparency;
                    break;
                default:
                    pixelData[pixelIndex] = 255 * vol;
                    pixelData[pixelIndex + 1] = 255 * vol;
                    pixelData[pixelIndex + 2] = 255 * vol;
                    pixelData[pixelIndex + 3] = transparency;
                    break;
            }
            
            
        }
    }
    
    void *baseAddress = &pixelData;
    
    size_t bytesPerRow = m_cols * 4;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress, m_cols, m_rows, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage* uiImage = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);

    UIGraphicsEndImageContext();
    return uiImage;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    NSLog(@"view will transition");
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
  if(UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape(deviceOrientation))
  {
    AVCaptureVideoPreviewLayer *previewLayer = [_previewView videoPreviewLayer];
    previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
  }
}

-(IBAction)orientationSwitch:(id)sender {
    NSLog(@"orientation switch");
    
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    if(appDelegate.currentOrientation == UIInterfaceOrientationPortrait) {
        [AppDelegate forceOrientation: UIInterfaceOrientationLandscapeRight];
    } else {
        [AppDelegate forceOrientation: UIInterfaceOrientationPortrait];
    }
    
    [self restartEngine];
}

@end


