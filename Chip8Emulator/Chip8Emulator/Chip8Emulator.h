//
//  Chip8Emulator.h
//  Chip8Emulator
//
//  Created by Joel Reed on 2/22/14.
//  Copyright (c) 2014 Joel Reed. All rights reserved.
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

#import <Foundation/Foundation.h>

#import "Chip8State.h"


typedef enum Chip8ErrorId : NSUInteger {
    illegalOpcode,
    illegalProgramCounter,
    stackOverflow
} Chip8ErrorId;


@protocol Chip8EmulatorDelegate <NSObject>

- (void)chip8GFXPlotX:(uint8_t)x Y:(uint8_t)y Value:(uint8_t)value;
- (void)chip8Error:(Chip8ErrorId)errorId message:(NSString*)errorMessage;

@optional

- (BOOL)chip8StartRequested;
- (void)chip8StartComplete;
- (BOOL)chip8StepRequested;
- (void)chip8StepComplete;
- (BOOL)chip8StopRequested;
- (void)chip8StopComplete;
- (BOOL)chip8ContinueRequested;
- (void)chip8ContinueComplete;
- (BOOL)chip8ResetRequested;
- (void)chip8ResetComplete;
- (void)chip8SpeedSetHz:(uint16_t)theSpeed;
- (void)chip8CycleTimeOverflow:(double)theAmount;
- (void)chip8State:(Chip8State*)theState;

@end


@interface Chip8Emulator : NSObject

@property (nonatomic, weak) id <Chip8EmulatorDelegate> delegate;

- (id)init;
- (id)initWithDelegate:(id)theDelegate;
- (id)initWithDelegate:(id)theDelegate andProgram:(NSData*)theProgram;
- (void)setClockSpeedHz:(uint16_t)theSpeed;
- (void)load:(NSData*)theProgram;
- (void)run;
- (BOOL)running;
- (void)step;
- (void)continue;
- (void)stop;
- (void)reset;
- (void)buttonPress:(uint8_t)button;
- (void)buttonRelease:(uint8_t)button;

@end
