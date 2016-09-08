//
//  JCMyScene.h
//  JCInput
//

//  Copyright (c) 2013 Juan Carlos Sedano Salas. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "JoystickDelegate.h"

@interface JCMyScene : SKScene

@property (nonatomic, weak) id<JoystickDelegate> joystickDelegate;

@end
