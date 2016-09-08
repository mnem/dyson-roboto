//
//  NSError+Ultratron.m
//  Ultratron
//
//  Created by David Wagner on 08/09/2016.
//  Copyright © 2016 Noise & Heat. All rights reserved.
//

#import "NSError+Ultratron.h"

NSString * const UltratronErrorDomain = @"ultratron";

NS_ASSUME_NONNULL_BEGIN

@implementation NSError (Ultratron)

+ (instancetype)ult_errorWithCode:(NSInteger)code message:(NSString *)message {
    return [NSError errorWithDomain:UltratronErrorDomain
                                code:code
                            userInfo:@{@"message":message}];
}

+ (instancetype)ult_couldNotConnectToBotAtIPAddress:(NSString *)address {
    NSString *message = [NSString stringWithFormat:@"Failed to connect to %@", address];
    return [NSError ult_errorWithCode:UltratronErrorCouldNotConnectToBot message:message];
}

@end

NS_ASSUME_NONNULL_END
