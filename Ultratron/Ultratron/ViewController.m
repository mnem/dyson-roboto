//
//  ViewController.m
//  Ultratron
//
//  Created by David Wagner on 08/09/2016.
//  Copyright © 2016 Noise & Heat. All rights reserved.
//

#import "ViewController.h"
#import "Commander.h"

@interface ViewController () <CommanderDelegate>
@property (nonatomic) Commander *commander;
@property (weak, nonatomic) IBOutlet UIButton *left;
@property (weak, nonatomic) IBOutlet UIButton *zero;
@property (weak, nonatomic) IBOutlet UIButton *right;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.commander = [[Commander alloc] init];
    self.commander.delegate = self;
    [self.commander connectToIPAddress:@"192.168.1.113" handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Could not connect: %@", error);
            return;
        }
        
        self.left.enabled = YES;
        self.zero.enabled = YES;
        self.right.enabled = YES;
    }];
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

-(void)imageFeedUpdated:(UIImage *)image
{
    NSLog(@"Image");
}


@end
