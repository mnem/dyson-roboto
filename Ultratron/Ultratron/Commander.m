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
#define LOG_UNSUBSCRIBED_TOPIC_DATA (1)

NS_ASSUME_NONNULL_BEGIN

@interface Commander () <MQTTSessionDelegate>
@property (nonatomic, nullable) MQTTSession *session;
@property (nonatomic) NSURLSession *imageFeedSession;
@property (nonatomic) NSTimer *imageFeedPollingTimer;
@property (nonatomic) NSString *ipAddress;

@property (nonatomic) NSMutableDictionary<NSString *, SubscriptionHandler> *subscriptionHandlers;
@end

@implementation Commander

- (instancetype)init
{
    self = [super init];
    if (self) {
        _subscriptionHandlers = [NSMutableDictionary dictionary];
    }
    return self;
}

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
    
    MQTTQosLevel qos = MQTTQosLevelAtMostOnce;
    
#if USE_ASYNC_COMMANDS
    [self.session publishData:data
                      onTopic:topic
                       retain:NO
                          qos:qos
               publishHandler:^(NSError *error) {
                   if (error != nil) {
                       NSLog(@"Commander send command error: %@", error);
                   }
               }];
#else
    [self.session publishAndWaitData:data onTopic:topic retain:NO qos:qos];
#endif // USE_ASYNC_COMMANDS
}

#pragma mark - MQTTSessionDelegate

- (void)newMessage:(MQTTSession *)session
              data:(NSData *)data
           onTopic:(NSString *)topic
               qos:(MQTTQosLevel)qos
          retained:(BOOL)retained
               mid:(unsigned int)mid {
    SubscriptionHandler handler = self.subscriptionHandlers[topic];
    if (handler) {
        handler(topic, data);
    } else {
#if LOG_UNSUBSCRIBED_TOPIC_DATA
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@">>>>>>>>>> Recieved message for topic %@: %@", topic, string);
#endif // LOG_UNSUBSCRIBED_TOPIC_DATA
    }
}

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
//    NSLog(@"Poll for Image Feed");
    NSString *urlString = [NSString stringWithFormat:@"http://%@:8080/frame.jpg",self.ipAddress];
    
    NSURLSessionTask *task = [self.imageFeedSession dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        UIImage *image = [UIImage imageWithData:data];
//        NSLog(@"Image Received ");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate)
            {
                [self.delegate imageFeedUpdated:image];
            }
        });
    }];
    
    [task resume];
}

- (void)subscribeToTopic:(NSString *)topic withHandler:(SubscriptionHandler)handler {
    [self.session subscribeToTopic:topic
                      atLevel:2
             subscribeHandler:^(NSError *error, NSArray<NSNumber *> *gQoss){
                 if (error) {
                    NSLog(@"Subscription failed %@", error.localizedDescription);
                } else {
                    NSLog(@"Subscription sucessfull! Granted Qos: %@", gQoss);
#warning Lots of lovely retain cycles possible here. Fix at some point.
                    self.subscriptionHandlers[topic] = handler;
                }
             }];
}

- (void)unsubscribeFromTopic:(NSString *)topic {
    [self.subscriptionHandlers removeObjectForKey:topic];
    [self.session unsubscribeTopic:topic];
}


@end

NS_ASSUME_NONNULL_END
