
#import "ViewController.h"
#import "SynestheatreMain.h"
#import "SensorManager.h"
#import "PasswordViewController.h"
#import <ExternalAccessory/ExternalAccessory.h>

@interface ViewController () {
    AVSpeechSynthesizer *_synthesizer;
    SensorManager* _sensorManager;
    AudioController* _audioController;
    id<DepthSensor> _depthSensor;
}
@end


@implementation ViewController

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    static BOOL fromLaunch = YES;
    if(!fromLaunch) {
        // This gets called even when coming back from settings screen, so
        // it's not good to put in code to restart things etc, otherwise
        // multiple restarts happen
        return;
    }

    _sensorManager = [[SensorManager alloc] init];
    
    [[DebugViews sharedManager] setupWithParent:self.view];
    
    // STWirelessLog is very helpful for debugging while your Structure Sensor is plugged in.
    // See SDK documentation for how to start a listener on your computer.
    
    // To listen on mac, use: nc -lk 4999
    
    //NSError* error = nil;
    //NSString *remoteLogHost = @"139.184.164.179";
    
    //[STWirelessLog broadcastLogsToWirelessConsoleAtAddress:remoteLogHost usingPort:4999 error:&error];
    //if (error)
    //    NSLog(@"Oh no! Can't start wireless log: %@", [error localizedDescription]);
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(restartEngine:)
                                                 name:@"RestartEngine"
                                               object:nil];
    
    
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
    
    // Restart engine is called from here, in the first instance
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(restartEngine:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];

    fromLaunch = NO;
    [self restartEngine];
}

-(void) restartEngine:(NSNotification *) notification {
    dispatch_async(dispatch_get_main_queue(),^{
        [self restartEngine];
    });
}

-(void) sensorChanged:(NSNotification *) notification {
    
    NSLog(@"Sensor changed!");
    dispatch_async(dispatch_get_main_queue(), ^{
        // Clear views to reflect change
        [[DebugViews sharedManager] reset];
        [self restartEngine];
    });
}
    
/*
 * MUST be called from main thread
 */
-(void) restartEngine {

    // Load a UI to show laoding
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:@"Please wait..." preferredStyle:UIAlertControllerStyleAlert];
    
    UIActivityIndicatorView* loadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(10, 5, 50, 50)];
    [loadingIndicator setHidesWhenStopped:true];
    [loadingIndicator startAnimating];
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [alert.view addSubview:loadingIndicator];
    UIViewController* vc = [Toast topViewController];
    
    [vc presentViewController:alert animated:true completion:^{
        [self restartEngineWork];
        [vc dismissViewControllerAnimated:false completion:nil];
    }];
}
        
        
-(void) restartEngineWork {
    
    // This also stops the depth sensor
    if (_synestheatreMain != nil) {
        [_synestheatreMain stop];
        _synestheatreMain = nil;
    }
    
    _depthSensor = nil;
    _depthSensor = [_sensorManager getSensor];
    
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
    
    // Setup debug views
    DebugViews* debugViews = [DebugViews sharedManager];
    [debugViews setDepthSensor:_depthSensor];
    [debugViews setSynestheatreMain:_synestheatreMain];
    
    // Setup parameter controller
    _parameterController.debugViews = debugViews;
    _parameterController.synestheatreMain = _synestheatreMain;
    
    // Block for updates when new depth data arrives
    ViewController * __weak weakSelf = self;
    _depthSensor.newDataBlock = ^() {
        [weakSelf.synestheatreMain depthDataUpdated];
        [debugViews updateSensorImage];
    };
    
    
    // Start synestheatre
    [_synestheatreMain start];
}

// Called when leaving the main settings window
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    [[DebugViews sharedManager] reset];
}


#pragma mark speech

-(void)saySomething:(NSNotification*)notification {
    [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    NSString *something = notification.object;
    //NSLog(@"Saying: %@", something);
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:something];
    [utterance setRate:0.4f];
    [_synthesizer speakUtterance:utterance];
}

@end


