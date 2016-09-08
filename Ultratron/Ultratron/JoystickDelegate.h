//
//  JoystickDelegate.h
//  Ultratron
//
//  Created by Nicolas Badano on 9/8/16.
//  Copyright © 2016 Noise & Heat. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JoystickDelegate <NSObject>


- (void)updateWithLeftJoystick:(float)leftY andRightJoystick:(float)rightY;

@end
