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
        [self.joystickLeft setPosition:CGPointMake(80,200)];
        [self addChild:self.joystickLeft];
        //JCJoystick Right
        self.joystickRight = [[JCJoystick alloc] initWithControlRadius:40 baseRadius:45 baseColor:[SKColor blueColor] joystickRadius:25 joystickColor:[SKColor redColor]];
        [self.joystickRight setPosition:CGPointMake(400,200)];
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
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        

        
        
    }
    return self;
}

-(void)update:(CFTimeInterval)currentTime {

    [self.joystickDelegate updateWithLeftJoystick:self.joystickLeft.y andRightJoystick:self.joystickRight.y];
    
    /* Called before each frame is rendered */
}



- (void)addSquareIn:(CGPoint)position
          withColor:(SKColor *)color
{
    SKSpriteNode *square = [SKSpriteNode spriteNodeWithColor:color size:CGSizeMake(15,10)];
    [square setPosition:position];
    SKAction *move = [SKAction moveTo:CGPointMake(self.size.width+square.size.width/2,position.y) duration:1];
    SKAction *destroy = [SKAction removeFromParent];
    [self addChild:square];
    [square runAction:[SKAction sequence:@[move,destroy]]];
}

@end
