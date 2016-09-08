//
//  Commander.h
//  Ultratron
//
//  Created by David Wagner on 08/09/2016.
//  Copyright © 2016 Noise & Heat. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ConnectionHandler)(NSError * _Nullable);

NS_ASSUME_NONNULL_BEGIN

@interface Commander : NSObject

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

@end

NS_ASSUME_NONNULL_END
