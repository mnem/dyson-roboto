//
//  ViewController.m
//  Ultratron
//
//  Created by David Wagner on 08/09/2016.
//  Copyright © 2016 Noise & Heat. All rights reserved.
//

#import "ViewController.h"
#import "JCMyScene.h"
#import "Commander.h"

@interface ViewController () <JoystickDelegate, CommanderDelegate>
@property (nonatomic) Commander *commander;
@property (weak, nonatomic) IBOutlet SKView *spriteKitView;
@property (weak, nonatomic) IBOutlet UIButton *left;
@property (weak, nonatomic) IBOutlet UIButton *zero;
@property (weak, nonatomic) IBOutlet UIButton *right;
@property (strong) IBOutlet UIImageView *cameraFeedImage;
@property (strong) IBOutlet UIView *deactiveCameraIndicator;

@property (nonatomic,assign) float leftPower;
@property (nonatomic,assign) float rightPower;

@property (nonatomic,strong) NSTimer *sendCommandTimer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.leftPower = 0;
    self.rightPower = 0;
    
    self.sendCommandTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(trigerSendCommand) userInfo:nil repeats:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.commander = [[Commander alloc] init];
        self.commander.delegate = self;
        [self.commander connectToIPAddress:@"192.168.1.113" handler:^(NSError *error) {
            if (error != nil) {
                NSLog(@"Error connecting: %@", error);
                return;
            }
            
            NSLog(@"Connected!");
//            self.spriteKitView.paused = NO;
//            [self setupJoystickView];
        }];
        
    });
    
    
    [self setupJoystickView];
}

- (void)setupJoystickView {
    // Configure the view.
    SKView * skView = self.spriteKitView;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    skView.multipleTouchEnabled = YES;
    
    // Create and configure the scene.
    JCMyScene * scene = [JCMyScene sceneWithSize:CGSizeMake(skView.bounds.size.height,skView.bounds.size.width)];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    scene.joystickDelegate = self;
    
    // Present the scene.
    [skView presentScene:scene];
}

- (IBAction)handleLeft:(UIButton *)sender {
    NSDictionary *command = @{@"Left" : @(4000), @"Right" : @(-1000)};
    [self.commander sendCommandDictionary:command forTopic:@"command/wheel_speed"];
}
- (IBAction)handleRight:(UIButton *)sender {
    NSDictionary *command = @{@"Left" : @(-1000), @"Right" : @(4000)};
    [self.commander sendCommandDictionary:command forTopic:@"command/wheel_speed"];
}
- (IBAction)handleZero:(UIButton *)sender {
    NSDictionary *command = @{@"Left" : @(0), @"Right" : @(0)};
    [self.commander sendCommandDictionary:command forTopic:@"command/wheel_speed"];
}

#pragma mark - JoystickDelegate

- (void)updateWithLeftJoystick:(float)leftY andRightJoystick:(float)rightY {
    
    self.leftPower = leftY * 4000;
    self.rightPower = rightY * 4000;
    
    if (self.leftPower > 3500) {
        self.leftPower = 4000;
    }
    if (self.rightPower > 3500) {
        self.rightPower = 4000;
    }

}

- (void)trigerSendCommand {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *command = @{@"Left" : @(floor(self.leftPower)), @"Right" : @(floor(self.rightPower))};
        [self.commander sendCommandDictionary:command forTopic:@"command/wheel_speed"];
        
    });
    
    
    
}

-(void)imageFeedUpdated:(UIImage *)image
{
    if (image)
    {
        self.cameraFeedImage.image = image;
        self.deactiveCameraIndicator.hidden = YES;
    }
    else
    {
        self.deactiveCameraIndicator.hidden = NO;
    }
}

@end
