//
//  ViewController.m
//  Ultratron
//
//  Created by David Wagner on 08/09/2016.
//  Copyright © 2016 Noise & Heat. All rights reserved.
//

#import "ViewController.h"
#import "MQTTClient.h"

@interface ViewController () <MQTTSessionDelegate>
@property (nonatomic) MQTTSession *session;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupMQTT];
}

- (void)setupMQTT {
    MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
    transport.host = @"192.168.1.113";
    transport.port = 1883;
    
    self.session = [[MQTTSession alloc] init];
    self.session.transport = transport;
    self.session.protocolLevel = MQTTProtocolVersion31;
    
    self.session.delegate = self;
    
    [self.session connectAndWaitTimeout:30];  //this is part of the synchronous API}
    
    [self doCommand];
}

- (void)doCommand {
    NSDictionary *command = @{@"Left" : @(1000), @"Right" : @(1000)};
    NSData* data = [NSJSONSerialization dataWithJSONObject:command options:kNilOptions error:nil];
    
    [self.session publishAndWaitData:data
                             onTopic:@"command/wheel_speed"
                              retain:NO
                                 qos:MQTTQosLevelAtLeastOnce];
}

#pragma mark - MQTTSessionDelegate

- (IBAction)handleLeft:(UIButton *)sender {
    NSDictionary *command = @{@"Left" : @(4000), @"Right" : @(-4000)};
    NSData* data = [NSJSONSerialization dataWithJSONObject:command options:kNilOptions error:nil];
    
    [self.session publishAndWaitData:data
                             onTopic:@"command/wheel_speed"
                              retain:NO
                                 qos:MQTTQosLevelAtLeastOnce];
}
- (IBAction)handleRight:(UIButton *)sender {
    NSDictionary *command = @{@"Left" : @(-4000), @"Right" : @(4000)};
    NSData* data = [NSJSONSerialization dataWithJSONObject:command options:kNilOptions error:nil];
    
    [self.session publishAndWaitData:data
                             onTopic:@"command/wheel_speed"
                              retain:NO
                                 qos:MQTTQosLevelAtLeastOnce];
}
- (IBAction)handleZero:(UIButton *)sender {
    NSDictionary *command = @{@"Left" : @(0), @"Right" : @(0)};
    NSData* data = [NSJSONSerialization dataWithJSONObject:command options:kNilOptions error:nil];
    
    [self.session publishAndWaitData:data
                             onTopic:@"command/wheel_speed"
                              retain:NO
                                 qos:MQTTQosLevelAtLeastOnce];
}

@end
