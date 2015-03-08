//
//  Chip8State.h
//  Chip8Emulator
//
//  Created by Joel Reed on 2/24/14.
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

#import <stdint.h>

extern const uint8_t Chip8InstructionSize;
extern const uint16_t Chip8MemorySize;
extern const uint16_t Chip8ProgramLocation;
extern const uint8_t Chip8RegisterQuantity;
extern const uint8_t Chip8GraphicsWidth;
extern const uint8_t Chip8GraphicsHeight;
extern const uint8_t Chip8StackSize;
extern const uint8_t Chip8KeysQuantity;


@interface Chip8State : NSObject

@property (nonatomic) uint16_t opcode;
@property (nonatomic) uint8_t *memory;
@property (nonatomic) uint8_t *v;
@property (nonatomic) uint16_t i;
@property (nonatomic) uint16_t pc;
@property (nonatomic) uint8_t *gfx;
@property (nonatomic) uint8_t delay_timer;
@property (nonatomic) uint8_t sound_timer;
@property (nonatomic) uint16_t *stack;
@property (nonatomic) uint8_t sp;
@property (nonatomic) uint8_t *keys;

- (NSString*)description;

@end
