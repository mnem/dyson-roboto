//
//  Commander.m
//  Ultratron
//
//  Created by David Wagner on 08/09/2016.
//  Copyright © 2016 Noise & Heat. All rights reserved.
//

#import "Commander.h"
#import "MQTTClient.h"
#import "NSError+Ultratron.h"

#define USE_ASYNC_COMMANDS (0)
#define USE_ASYNC_CONNECT (0)

NS_ASSUME_NONNULL_BEGIN

@interface Commander () <MQTTSessionDelegate>
@property (nonatomic, nullable) MQTTSession *session;
@property (nonatomic) NSURLSession *imageFeedSession;
@property (nonatomic) NSTimer *imageFeedPollingTimer;
@property (nonatomic) NSString *ipAddress;
@end

@implementation Commander

- (void)connectToIPAddress:(NSString *)ipAddress handler:(ConnectionHandler)handler {
    self.ipAddress = ipAddress;
#if USE_ASYNC_CONNECT
    dispatch_block_t connector = ^{
#endif // USE_ASYNC_CONNECT
        MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
        transport.host = ipAddress;
        transport.port = 1883;
        
        self.session = [[MQTTSession alloc] init];
        self.session.transport = transport;
        self.session.protocolLevel = MQTTProtocolVersion31;
        
        self.session.delegate = self;
        
        const BOOL connected = [self.session connectAndWaitTimeout:30];  //this is part of the synchronous API
        
        NSError *error = nil;
        if (!connected) {
            error = [NSError ult_couldNotConnectToBotAtIPAddress:ipAddress];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(error);
        });
#if USE_ASYNC_CONNECT
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0u), connector);
#endif // USE_ASYNC_CONNECT
    [self setUpImageFeed];
}


- (void)sendCommandDictionary:(NSDictionary *)command forTopic:(NSString *)topic {
    if (![NSJSONSerialization isValidJSONObject:command]) {
        NSLog(@"WARNING: sendCommandDictionary ignoring command to topic '%@' as dictionary cannot be converted to JSON.", topic);
        return;
    }
    
    NSData* data = [NSJSONSerialization dataWithJSONObject:command options:kNilOptions error:nil];
    
#if USE_ASYNC_COMMANDS
    [self.session publishData:data
                      onTopic:topic
                       retain:NO
                          qos:MQTTQosLevelAtLeastOnce
               publishHandler:^(NSError *error) {
                   if (error != nil) {
                       NSLog(@"Commander send command error: %@", error);
                   }
               }];
#else
    [self.session publishAndWaitData:data onTopic:topic retain:NO qos:MQTTQosLevelAtLeastOnce];
#endif // USE_ASYNC_COMMANDS
}

#pragma mark - MQTTSessionDelegate

#pragma mark - ImageFeedSetup

- (void)setUpImageFeed{
    [self setupURLSession];
    [self subscribeForImageFeed];
}

- (void)setupURLSession {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPMaximumConnectionsPerHost = 1;
    self.imageFeedSession = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[[NSOperationQueue alloc] init]];
}

- (void)subscribeForImageFeed
{
    _imageFeedPollingTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                              target:self
                                                            selector:@selector(poll)
                                                            userInfo:nil
                                                             repeats:YES];
    NSLog(@"Subscribe for image Feed");
    
}

#pragma mark - Poll

- (void)poll
{
    NSLog(@"Poll for Image Feed");
    NSString *urlString = [NSString stringWithFormat:@"http://%@:8080/frame.jpg",self.ipAddress];
    
    NSURLSessionTask *task = [self.imageFeedSession dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        UIImage *image = [UIImage imageWithData:data];
        NSLog(@"Image Received ");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate)
            {
                [self.delegate imageFeedUpdated:image];
            }
        });
    }];
    
    [task resume];
}



@end

NS_ASSUME_NONNULL_END
