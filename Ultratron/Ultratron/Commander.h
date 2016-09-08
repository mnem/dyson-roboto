//
//  Commander.h
//  Ultratron
//
//  Created by David Wagner on 08/09/2016.
//  Copyright © 2016 Noise & Heat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol CommanderDelegate <NSObject>
@required
-(void)imageFeedUpdated:(UIImage *)image;

@end

NS_ASSUME_NONNULL_BEGIN

typedef void (^ConnectionHandler)(NSError * _Nullable);
typedef void (^SubscriptionHandler)(NSString *topic, NSData *data);

@interface Commander : NSObject

@property (weak) id<CommanderDelegate> delegate;

/**
 Attempts to connect to the specified IP address on the standard port, using
 protocol 3.1.
 
 @param ipAddress   NSString ip address to connect to.
 @param handler     Callback when the connection completes or fails. Will be called on the main thread.
 */
- (void)connectToIPAddress:(NSString *)ipAddress handler:(ConnectionHandler)handler;

/**
 Send the specified command to the topic.
 
 @param command Command dictionary to be converted to JSON and sent to the topic.
 @param topic   The topic to send the command to.
 */
- (void)sendCommandDictionary:(NSDictionary *)command forTopic:(NSString *)topic;

/**
 Subscribe to the specified topic.
 
 @param topic   The topic to subscribe to.
 @param handler The handler which recieves topic data. Only 1 handler may be active for a given topic.
 */
- (void)subscribeToTopic:(NSString *)topic withHandler:(SubscriptionHandler)handler;

@end

NS_ASSUME_NONNULL_END
