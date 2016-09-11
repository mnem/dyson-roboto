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
#import "opencv2/opencv.hpp"

#define USE_ASYNC_COMMANDS (0)
#define USE_ASYNC_CONNECT (0)
#define USE_OPEN_CV (1)
#define LOG_UNSUBSCRIBED_TOPIC_DATA (1)








void build_map(int width, int height, cv::Mat & map_x, cv::Mat & map_y) {
    const auto PI = 3.1415926;
    const auto midx = width / 2;
    const auto midy = height / 2;
    const auto maxmag = fmax(midx, midy);
    const auto circum = 2 * PI * maxmag;
    
    map_x.create(static_cast<int>(maxmag), static_cast<int>(circum), CV_32FC1);
    map_y.create(static_cast<int>(maxmag), static_cast<int>(circum), CV_32FC1);
    for(int j = 0; j < static_cast<int>(maxmag); j++) {
        for(int i = 0; i < static_cast<int>(circum); i++) {
            const auto r = static_cast<float>(j);
            const auto theta = (static_cast<float>(i) / maxmag);
            const auto xs = midx - r * sin(theta);
            const auto ys = midy - r * cos(theta);
            map_x.at<float>(j, i) = xs;
            map_y.at<float>(j, i) = ys;
            //map_x.at<float>(j, i) = i;
            //map_y.at<float>(j, i) = j;
        }
    }
}








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
        
        const BOOL connected = [self.session connectAndWaitTimeout:0.1];  //this is part of the synchronous API
        
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

#if USE_OPEN_CV
- (void)poll
{
    UIImage *image = [UIImage imageNamed:@"placeholderView" inBundle:[NSBundle mainBundle] compatibleWithTraitCollection:nil];

    cv::Mat unwrapped = [self cvMatFromUIImage:image];

    static cv::Mat map_x;
    static cv::Mat map_y;
    static dispatch_once_t onceToken2;
    dispatch_once(&onceToken2, ^{
        build_map(unwrapped.cols, unwrapped.rows, map_x, map_y);
    });

    cv::Mat remapped;
    cv::remap(unwrapped, remapped, map_x, map_y, CV_INTER_LINEAR);

    image = [self UIImageFromCVMat:remapped];
    
    if ([self.delegate respondsToSelector:@selector(imageFeedUpdated:)]) {
        [self.delegate imageFeedUpdated:image];
    }
    
//    NSLog(@"Poll for Image Feed");
//    NSString *urlString = [NSString stringWithFormat:@"http://%@:8080/frame.jpg",self.ipAddress];
//    
//    NSURLSessionTask *task = [self.imageFeedSession dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        
//        UIImage *image = [UIImage imageWithData:data];
//        NSLog(@"Image Received ");
//        
//        cv::Mat unwrapped = [self cvMatFromUIImage:image];
//        
//        static cv::Mat map_x;
//        static cv::Mat map_y;
//        static dispatch_once_t onceToken;
//        dispatch_once(&onceToken, ^{
//            build_map(unwrapped.cols, unwrapped.rows, map_x, map_y);
//        });
//        
//        
//        
//        cv::Mat remapped;
//        cv::remap(unwrapped, remapped, map_x, map_y, CV_INTER_LINEAR);
//        
//        image = [self UIImageFromCVMat:remapped];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (self.delegate)
//            {
//                [self.delegate imageFeedUpdated:image];
//            }
//        });
//    }];
//    
//    [task resume];
}
#else
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
#endif // USE_OPEN_CV

- (void)subscribeToTopic:(NSString *)topic withHandler:(SubscriptionHandler)handler {
    [self.session subscribeToTopic:topic
                           atLevel:MQTTQosLevelExactlyOnce
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

#pragma mark - OpenCV

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
//                                                    colorSpace,                 // Colorspace
                                                    CGColorSpaceCreateDeviceRGB(),                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}


- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


@end

NS_ASSUME_NONNULL_END
