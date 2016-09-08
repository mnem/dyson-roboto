//
//  JCMyScene.m
//  JCInput
//
//  Created by Juan Carlos Sedano Salas on 19/09/13.
//  Copyright (c) 2013 Juan Carlos Sedano Salas. All rights reserved.
//

#import "JCMyScene.h"
#import "JCJoystick.h"
#import "JCImageJoystick.h"
#import "JCButton.h"
@interface JCMyScene()
    @property (strong, nonatomic) JCJoystick *joystickLeft;
    @property (strong, nonatomic) JCImageJoystick *imageJoystickLeft;

    @property (strong, nonatomic) JCJoystick *joystickRight;
    @property (strong, nonatomic) JCImageJoystick *imageJoystickRight;


@end

@implementation JCMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        //JCJoystick Left
        self.joystickLeft = [[JCJoystick alloc] initWithControlRadius:40 baseRadius:45 baseColor:[SKColor blueColor] joystickRadius:25 joystickColor:[SKColor redColor]];
        [self.joystickLeft setPosition:CGPointMake(80,280)];
        [self addChild:self.joystickLeft];
        //JCJoystick Right
        self.joystickRight = [[JCJoystick alloc] initWithControlRadius:40 baseRadius:45 baseColor:[SKColor blueColor] joystickRadius:25 joystickColor:[SKColor redColor]];
        [self.joystickRight setPosition:CGPointMake(500,280)];
        [self addChild:self.joystickRight];
        
        
        
//        //JCImageJoystic Right
//        self.imageJoystickRight = [[JCImageJoystick alloc]initWithJoystickImage:(@"redStick.png") baseImage:@"stickbase.png"];
//        [self.imageJoystickRight setPosition:CGPointMake(400, 200)];
//        [self addChild:self.imageJoystickRight];
//        //JCImageJoystic Left
//        self.imageJoystickLeft = [[JCImageJoystick alloc]initWithJoystickImage:(@"redStick.png") baseImage:@"stickbase.png"];
//        [self.imageJoystickLeft setPosition:CGPointMake(80, 200)];
//        [self addChild:self.imageJoystickLeft];

        
        
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor clearColor];
        

        
        
    }
    return self;
}

-(void)update:(CFTimeInterval)currentTime {

    if ([self.joystickDelegate respondsToSelector:@selector(updateWithLeftJoystick:andRightJoystick:)]) {
        [self.joystickDelegate updateWithLeftJoystick:self.joystickLeft.y andRightJoystick:self.joystickRight.y];
    }
    
    /* Called before each frame is rendered */
}



@end
