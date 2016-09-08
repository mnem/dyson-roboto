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

NSString * const kTopicWheelSpeed = @"command/wheel_speed";
NSString * const kTopicStatusBumps = @"status/bumps";
NSString * const kTopicStatusPsd = @"status/psd";
NSString * const kTopicStatusOdemetry = @"status/odemetry";

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
        [self setupSubscriptions];
    }];
}

- (void)setupSubscriptions {
    [self.commander subscribeToTopic:kTopicWheelSpeed
                         withHandler:^(NSString *topic, NSData * _Nonnull data) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Wheel speed: %@", string);
    }];

    [self.commander subscribeToTopic:kTopicStatusBumps
                         withHandler:^(NSString *topic, NSData * _Nonnull data) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"BUMPS! %@", string);
    }];

    [self.commander subscribeToTopic:kTopicStatusPsd
                         withHandler:^(NSString *topic, NSData * _Nonnull data) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"PSD: %@", string);
    }];
    
    [self.commander subscribeToTopic:kTopicStatusOdemetry
                         withHandler:^(NSString *topic, NSData * _Nonnull data) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Odemetry: %@", string);
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
    [self.commander sendCommandDictionary:command forTopic:kTopicWheelSpeed];
}
- (IBAction)handleRight:(UIButton *)sender {
    NSDictionary *command = @{@"Left" : @(-4000), @"Right" : @(4000)};
    [self.commander sendCommandDictionary:command forTopic:kTopicWheelSpeed];
}
- (IBAction)handleZero:(UIButton *)sender {
    NSDictionary *command = @{@"Left" : @(0), @"Right" : @(0)};
    [self.commander sendCommandDictionary:command forTopic:kTopicWheelSpeed];
}

#pragma mark - JoystickDelegate

- (void)updateWithLeftJoystick:(float)leftY andRightJoystick:(float)rightY {
//    NSLog(@"Updating joytstick");
    double leftPower = leftY * 4000.0;
    double rightPower = rightY * 4000.0;
//    NSLog(@"left:%f right:%f",leftPower, rightPower);
    
    NSDictionary *command = @{@"Left" : @(leftPower), @"Right" : @(rightPower)};
    [self.commander sendCommandDictionary:command forTopic:kTopicWheelSpeed];

//        NSDictionary *command = @{@"Left" : @(4000), @"Right" : @(-4000)};
//        [self.commander sendCommandDictionary:command forTopic:@"command/wheel_speed"];

    //    [self doCommand:leftPower and:rightPower];
}

-(void)imageFeedUpdated:(UIImage *)image
{
    self.cameraFeedImage.image = image;
}

@end
