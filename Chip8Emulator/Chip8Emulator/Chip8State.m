//
//  Chip8State.m
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

#import "Chip8StatePrivate.h"

const uint8_t Chip8InstructionSize = 0x2;
const uint16_t Chip8MemorySize = 0x1000;
const uint16_t Chip8ProgramLocation = 0x200;
const uint8_t Chip8RegisterQuantity = 0xF;
const uint8_t Chip8GraphicsWidth = 0x40;
const uint8_t Chip8GraphicsHeight = 0x20;
const uint8_t Chip8StackSize = 0xF;
const uint8_t Chip8KeysQuantity = 0xF;

static uint8_t const Chip8Fontset[] = {
    0xF0, 0x90, 0x90, 0x90, 0xF0,
    0x20, 0x60, 0x20, 0x20, 0x70,
    0xF0, 0x10, 0xF0, 0x80, 0xF0,
    0xF0, 0x10, 0xF0, 0x10, 0xF0,
    0x90, 0x90, 0xF0, 0x10, 0x10,
    0xF0, 0x80, 0xF0, 0x10, 0xF0,
    0xF0, 0x80, 0xF0, 0x90, 0xF0,
    0xF0, 0x10, 0x20, 0x40, 0x40,
    0xF0, 0x90, 0xF0, 0x90, 0xF0,
    0xF0, 0x90, 0xF0, 0x10, 0xF0,
    0xF0, 0x90, 0xF0, 0x90, 0x90,
    0xE0, 0x90, 0xE0, 0x90, 0xE0,
    0xF0, 0x80, 0x80, 0x80, 0xF0,
    0xE0, 0x90, 0x90, 0x90, 0xE0,
    0xF0, 0x80, 0xF0, 0x80, 0xF0,
    0xF0, 0x80, 0xF0, 0x80, 0x80
};
static uint8_t const Chip8FontsetLen = 80;


@implementation Chip8State

- (id)init {
    self = [super init];
    if (self != nil) {
        self.memory = malloc(Chip8MemorySize);
        self.v = malloc(Chip8RegisterQuantity);
        self.gfx = malloc(Chip8GraphicsWidth * Chip8GraphicsHeight);
        self.stack = malloc(Chip8StackSize);
        self.keys = malloc(Chip8KeysQuantity);
        [self clearState];
    }
    return self;
}

- (void)clearState {
    self.opcode = 0x0;
    for(int a=0; a<Chip8MemorySize; a++) {
        self.memory[a] = 0x0;
    }
    
    [self resetState];
}

- (void)resetState {
    for(int a=0; a<Chip8FontsetLen; a++) {
        self.memory[a] = Chip8Fontset[a];
    }
    for(int a=0; a<Chip8RegisterQuantity; a++) {
        self.v[a] = 0x0;
    }
    self.i = 0x0;
    self.pc = Chip8ProgramLocation;
    for(int a=0; a<Chip8GraphicsWidth*Chip8GraphicsHeight; a++) {
        self.gfx[a] = 0x0;
    }
    self.delay_timer = 0xff;
    self.sound_timer = 0xff;
    for(int a=0; a<Chip8StackSize; a++) {
        self.stack[a] = 0x0;
    }
    self.sp = 0;
    for(int a=0; a<Chip8KeysQuantity; a++) {
        self.keys[a] = 0x0;
    }
}

- (void)loadProgram:(NSData*)theProgram {
    [self clearState];
    uint8_t *bytes = (uint8_t*)[theProgram bytes];
    for(int a=0; a<[theProgram length]; a++) {
        self.memory[a + Chip8ProgramLocation] = bytes[a];
    }
}

- (NSString*)description {
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendString:@"\n"];
    [s appendString:[NSString stringWithFormat:@"Opcode: %.4X\n", self.opcode]];
    [s appendString:[NSString stringWithFormat:@"PC: %.4X\n", self.pc]];
    [s appendString:@"Registers:\n"];
    for(int a=0; a<Chip8RegisterQuantity; a++) {
        [s appendString:[NSString stringWithFormat:@"\tV%X=%.2X;  ", a, self.v[a]]];
        if ((a + 1) % 4 == 0) {
            [s appendString:@"\n"];
        }
    }
    [s appendString:@"\n"];
    [s appendString:[NSString stringWithFormat:@"SP: %.2X\n", self.sp]];
    for(int a=0; a<Chip8StackSize; a++) {
        [s appendString:[NSString stringWithFormat:@"\tS:%X=%.2X;  ", a, self.stack[a]]];
        if ((a + 1) % 4 == 0) {
            [s appendString:@"\n"];
        }
    }
    [s appendString:@"\n"];
    [s appendString:[NSString stringWithFormat:@"Delay: %.2X\n", self.delay_timer]];
    [s appendString:[NSString stringWithFormat:@"Sound: %.2X\n", self.sound_timer]];
    return s;
}

- (void)dealloc {
    free(self.memory);
    free(self.v);
    free(self.gfx);
    free(self.stack);
    free(self.keys);
}

@end
