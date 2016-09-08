//
//  NSError+Ultratron.h
//  Ultratron
//
//  Created by David Wagner on 08/09/2016.
//  Copyright © 2016 Noise & Heat. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, UltratronError) {
    UltratronErrorCouldNotConnectToBot = 1,
};

NS_ASSUME_NONNULL_BEGIN

extern NSString * const UltratronErrorDomain;

@interface NSError (Ultratron)

+ (instancetype)ult_couldNotConnectToBotAtIPAddress:(NSString *)address;

@end

NS_ASSUME_NONNULL_END
