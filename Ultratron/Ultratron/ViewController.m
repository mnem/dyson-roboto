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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.spriteKitView.paused = YES;
    
    self.commander = [[Commander alloc] init];
    self.commander.delegate = self;
    [self.commander connectToIPAddress:@"192.168.1.113" handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Error connecting: %@", error);
            return;
        }
        
        NSLog(@"Connected!");
        self.spriteKitView.paused = NO;
        [self setupJoystickView];
    }];
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
    NSDictionary *command = @{@"Left" : @(4000), @"Right" : @(-4000)};
    [self.commander sendCommandDictionary:command forTopic:@"command/wheel_speed"];
}
- (IBAction)handleRight:(UIButton *)sender {
    NSDictionary *command = @{@"Left" : @(-4000), @"Right" : @(4000)};
    [self.commander sendCommandDictionary:command forTopic:@"command/wheel_speed"];
}
- (IBAction)handleZero:(UIButton *)sender {
    NSDictionary *command = @{@"Left" : @(0), @"Right" : @(0)};
    [self.commander sendCommandDictionary:command forTopic:@"command/wheel_speed"];
}

#pragma mark - JoystickDelegate

- (void)updateWithLeftJoystick:(float)leftY andRightJoystick:(float)rightY {
    NSLog(@"Updating joytstick");
    float leftPower = leftY * 4000;
    float rightPower = rightY * 4000;
    NSLog(@"left:%f right:%f",leftPower, rightPower);
    
    NSDictionary *command = @{@"Left" : @(leftPower), @"Right" : @(rightPower)};
//    [self.commander sendCommandDictionary:command forTopic:@"command/wheel_speed"];

    //    [self doCommand:leftPower and:rightPower];
}

-(void)imageFeedUpdated:(UIImage *)image
{
    self.cameraFeedImage.image = image;
}

@end
