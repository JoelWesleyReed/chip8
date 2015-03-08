//
//  Chip8Emulator.m
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

#import <stdint.h>

#import "Chip8Emulator.h"
#import "Chip8StatePrivate.h"


static const uint16_t DEFAULT_CLOCK_SPEED = 1000;


@interface Chip8Emulator ()

- (void)doStep;
- (void)clearScreen;

@end


@implementation Chip8Emulator {
    float clockSpeed;
    Chip8State *state;
    bool running;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        state = [[Chip8State alloc] init];
        [self setClockSpeedHz:DEFAULT_CLOCK_SPEED];
    }
    return(self);
}

- (id)initWithDelegate:(id)theDelegate {
    self = [self init];
    if (self != nil) {
        self.delegate = theDelegate;
    }
    return self;
}

- (id)initWithDelegate:(id)theDelegate andProgram:(NSData*)theProgram {
    self = [self initWithDelegate:theDelegate];
    if (self != nil) {
        [self load:theProgram];
    }
    return self;
}

- (void)setClockSpeedHz:(uint16_t)theSpeed {
    clockSpeed = 1.0 / (float) theSpeed;
    if ([self.delegate respondsToSelector:@selector(chip8SpeedSetHz:)]) {
        [self.delegate chip8SpeedSetHz:theSpeed];
    }
}

- (void)load:(NSData*)theProgram {
    if (running) {
        [self stop];
    }
    [state loadProgram:theProgram];
    if ([self.delegate respondsToSelector:@selector(chip8State:)]) {
        [self.delegate chip8State:state];
    }
}

- (void)run {
    if (!running) {
        BOOL canStart = YES;
        if ([self.delegate respondsToSelector:@selector(chip8StartRequested)]) {
            canStart = [self.delegate chip8StartRequested];
        }
        
        if (canStart) {
            if ([self.delegate respondsToSelector:@selector(chip8StartComplete)]) {
                [self.delegate chip8StartComplete];
            }
            running = YES;
            while(running) {
                [self doStep];
            }
            if ([self.delegate respondsToSelector:@selector(chip8StopComplete)]) {
                [self.delegate chip8StopComplete];
            }
        }
    }
}

- (BOOL)running {
    return running;
}

- (void)step {
    if (!running) {
        BOOL canStep = YES;
        if ([self.delegate respondsToSelector:@selector(chip8StepRequested)]) {
            canStep = [self.delegate chip8StepRequested];
        }
        
        if (canStep) {
            [self doStep];
            
            if ([self.delegate respondsToSelector:@selector(chip8StepComplete)]) {
                [self.delegate chip8StepComplete];
            }
        }
    }
}

- (void)continue {
    if (!running) {
        BOOL canContinue = YES;
        if ([self.delegate respondsToSelector:@selector(chip8ContinueRequested)]) {
            canContinue = [self.delegate chip8ContinueRequested];
        }
        
        if (canContinue) {
            running = YES;
            if ([self.delegate respondsToSelector:@selector(chip8ContinueComplete)]) {
                [self.delegate chip8ContinueComplete];
            }
            [self run];
        }
    }
}

- (void)stop {
    if (running) {
        BOOL canStop = YES;
        if ([self.delegate respondsToSelector:@selector(chip8StopRequested)]) {
            canStop = [self.delegate chip8StopRequested];
        }
        
        if (canStop) {
            running = NO;
            if ([self.delegate respondsToSelector:@selector(chip8StopComplete)]) {
                [self.delegate chip8StopComplete];
            }
        }
    }
}

- (void)reset {
    if (running) {
        [self stop];
    }
    
    if (!running) {
        BOOL canReset = YES;
        if ([self.delegate respondsToSelector:@selector(chip8ResetRequested)]) {
            canReset = [self.delegate chip8ResetRequested];
        }
        
        if (canReset) {
            [state resetState];
            
            [self clearScreen];
            
            if ([self.delegate respondsToSelector:@selector(chip8State:)]) {
                [self.delegate chip8State:state];
            }
            
            if ([self.delegate respondsToSelector:@selector(chip8ResetComplete)]) {
                [self.delegate chip8ResetComplete];
            }
        }
    }
}

- (void)buttonPress:(uint8_t)button {
    state.keys[button] = 0x1;
    if ([self.delegate respondsToSelector:@selector(chip8State:)]) {
        [self.delegate chip8State:state];
    }
}

- (void)buttonRelease:(uint8_t)button {
    state.keys[button] = 0x0;
    if ([self.delegate respondsToSelector:@selector(chip8State:)]) {
        [self.delegate chip8State:state];
    }
}

#pragma mark - private methods

- (void)doStep {
    @autoreleasepool {
        NSDate *startTime = [NSDate date];
        state.opcode = state.memory[state.pc] << 8 | state.memory[state.pc + 1];
        [self op_0x____];
        if ([self.delegate respondsToSelector:@selector(chip8State:)]) {
            [self.delegate chip8State:state];
        }
        if (state.delay_timer > 0) {
            state.delay_timer--;
        }
        if (state.sound_timer > 0) {
            state.sound_timer--;
        }
        double timePassed = -[startTime timeIntervalSinceNow];
        if (timePassed < clockSpeed) {
            [NSThread sleepForTimeInterval:(clockSpeed - timePassed)];
        }
        else {
            if ([self.delegate respondsToSelector:@selector(chip8CycleTimeOverflow:)]) {
                [self.delegate chip8CycleTimeOverflow:-(clockSpeed - timePassed)];
            }
        }
        if (state.pc < Chip8ProgramLocation || state.pc > Chip8MemorySize) {
            [self.delegate chip8Error:illegalProgramCounter message:[NSString stringWithFormat:@"illegal program counter: 0x%.4X", state.pc]];
            running = NO;
        }
    }
}

- (void)clearScreen {
    for(int y=0; y<Chip8GraphicsHeight; y++) {
        for(int x=0; x<Chip8GraphicsWidth; x++) {
            state.gfx[x + (y * Chip8GraphicsWidth)] = 0x0;
            if (self.delegate != nil) {
                [self.delegate chip8GFXPlotX:x Y:y Value:0x0];
            }
        }
    }
}

#pragma mark - opcode methods

// 0x????
- (void)op_0x____ {
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"op_0x%X___", (state.opcode & 0xF000) >> 12]);
    if ([self respondsToSelector:selector]) {
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(self, selector);
    }
    else {
        [self.delegate chip8Error:illegalOpcode message:[NSString stringWithFormat:@"illegal opcode: 0x%.4X at 0x%.4X", state.opcode, state.pc]];
        running = NO;
    }
}

// 0x0???
- (void)op_0x0___ {
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"op_0x00%.2X", state.opcode & 0x00FF]);
    if ([self respondsToSelector:selector]) {
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(self, selector);
    }
    else {
        [self.delegate chip8Error:illegalOpcode message:[NSString stringWithFormat:@"illegal opcode: 0x%.4X at 0x%.4X", state.opcode, state.pc]];
        running = NO;
    }
}

// 0x00E0 - Clear the screen.
- (void)op_0x00E0 {
    [self clearScreen];
    state.pc += 2;
}

// 0x00EE - Returns from a subroutine.
- (void)op_0x00EE {
    --state.sp;
    state.pc = state.stack[state.sp];
    state.stack[state.sp] = 0x0;
    state.pc += 2;
}

// 0x1NNN - Jumps to address NNN.
- (void)op_0x1___ {
    state.pc = state.opcode & 0x0FFF;
}

// 0x2NNN - Calls subroutine at NNN.
- (void)op_0x2___ {
    state.stack[state.sp] = state.pc;
    ++state.sp;
    state.pc = state.opcode & 0x0FFF;
    if (state.sp > Chip8StackSize) {
        [self.delegate chip8Error:stackOverflow message:@"stack overflow"];
        running = NO;
    }
}

// 0x3XNN - Skips the next instruction if VX equals NN.
- (void)op_0x3___ {
    if(state.v[(state.opcode & 0x0F00) >> 8] == (state.opcode & 0x00FF)) {
        state.pc += 4;
    }
    else {
        state.pc += 2;
    }
}

// 0x4XNN Skips the next instruction if VX doesn't equal NN.
- (void)op_0x4___ {
    if(state.v[(state.opcode & 0x0F00) >> 8] != (state.opcode & 0x00FF)) {
        state.pc += 4;
    }
    else {
        state.pc += 2;
    }
}

// 0x5???
- (void)op_0x5___ {
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"op_0x5__%X", state.opcode & 0x000F]);
    if ([self respondsToSelector:selector]) {
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(self, selector);
    }
    else {
        [self.delegate chip8Error:illegalOpcode message:[NSString stringWithFormat:@"illegal opcode: 0x%.4X at 0x%.4X", state.opcode, state.pc]];
        running = NO;
    }
}

// 0x5XY0 - Skips the next instruction if VX equals VY.
- (void)op_0x5__0 {
    if(state.v[(state.opcode & 0x0F00) >> 8] == state.v[(state.opcode & 0x00F0) >> 4]) {
        state.pc += 4;
    }
    else {
        state.pc += 2;
    }
}

// 0x6XNN - Sets VX to NN
- (void)op_0x6___ {
    state.v[(state.opcode & 0x0F00) >> 8] = state.opcode & 0x00FF;
    state.pc += 2;
}

// 0x7XNN - Adds NN to VX
- (void)op_0x7___ {
    state.v[(state.opcode & 0x0F00) >> 8] += state.opcode & 0x00FF;
    state.pc += 2;
}

// 0x8???
- (void)op_0x8___ {
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"op_0x8__%X", state.opcode & 0x000F]);
    if ([self respondsToSelector:selector]) {
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(self, selector);
    }
    else {
        [self.delegate chip8Error:illegalOpcode message:[NSString stringWithFormat:@"illegal opcode: 0x%.4X at 0x%.4X", state.opcode, state.pc]];
        running = NO;
    }
}

// 0x8XY0 - Sets VX to the value of VY.
- (void)op_0x8__0 {
    state.v[(state.opcode & 0x0F00) >> 8] = state.v[(state.opcode & 0x00F0) >> 4];
    state.pc += 2;
}

// 0x8XY1 - Sets VX to VX or VY.
- (void)op_0x8__1 {
    state.v[(state.opcode & 0x0F00) >> 8] |= state.v[(state.opcode & 0x00F0) >> 4];
    state.pc += 2;
}

// 0x8XY2 - Sets VX to VX and VY.
- (void)op_0x8__2 {
    state.v[(state.opcode & 0x0F00) >> 8] &= state.v[(state.opcode & 0x00F0) >> 4];
    state.pc += 2;
}

// 0x8XY3 - Sets VX to VX xor VY.
- (void)op_0x8__3 {
    state.v[(state.opcode & 0x0F00) >> 8] ^= state.v[(state.opcode & 0x00F0) >> 4];
    state.pc += 2;
}

// 0x8XY4 - Adds VY to VX. VF is set to 1 when there's a carry, and to 0 when there isn't.
- (void)op_0x8__4 {
    if(state.v[(state.opcode & 0x00F0) >> 4] > (0xFF - state.v[(state.opcode & 0x0F00) >> 8])) {
        state.v[0xF] = 1;
    }
    else {
        state.v[0xF] = 0;
    }
    state.v[(state.opcode & 0x0F00) >> 8] += state.v[(state.opcode & 0x00F0) >> 4];
    state.pc += 2;
}

// 0x8XY5 - VY is subtracted from VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
- (void)op_0x8__5 {
    if(state.v[(state.opcode & 0x00F0) >> 4] > state.v[(state.opcode & 0x0F00) >> 8]) {
        state.v[0xF] = 0;
    }
    else {
        state.v[0xF] = 1;
    }
    state.v[(state.opcode & 0x0F00) >> 8] -= state.v[(state.opcode & 0x00F0) >> 4];
    state.pc += 2;
}

// 0x8XY6 - Shifts VX right by one. VF is set to the value of the least significant bit of VX before the shift.
- (void)op_0x8__6 {
    state.v[0xF] = state.v[(state.opcode & 0x0F00) >> 8] & 0x1;
    state.v[(state.opcode & 0x0F00) >> 8] >>= 1;
    state.pc += 2;
}

// 0x8XY7 - Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
- (void)op_0x8__7 {
    if(state.v[(state.opcode & 0x0F00) >> 8] > state.v[(state.opcode & 0x00F0) >> 4]) {
        state.v[0xF] = 0;
    }
    else {
        state.v[0xF] = 1;
    }
    state.v[(state.opcode & 0x0F00) >> 8] = state.v[(state.opcode & 0x00F0) >> 4] - state.v[(state.opcode & 0x0F00) >> 8];
    state.pc += 2;
}

// 0x8XYE - Shifts VX left by one. VF is set to the value of the most significant bit of VX before the shift.
- (void)op_0x8__E {
    state.v[0xF] = state.v[(state.opcode & 0x0F00) >> 8] >> 7;
    state.v[(state.opcode & 0x0F00) >> 8] <<= 1;
    state.pc += 2;
}

// 0x9???
- (void)op_0x9___ {
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"op_0x9__%X", state.opcode & 0x000F]);
    if ([self respondsToSelector:selector]) {
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(self, selector);
    }
    else {
        [self.delegate chip8Error:illegalOpcode message:[NSString stringWithFormat:@"illegal opcode: 0x%.4X at 0x%.4X", state.opcode, state.pc]];
        running = NO;
    }
}

// 0x9XY0 - Skips the next instruction if VX doesn't equal VY.
- (void)op_0x9__0 {
    if(state.v[(state.opcode & 0x0F00) >> 8] != state.v[(state.opcode & 0x00F0) >> 4]) {
        state.pc += 4;
    }
    else {
        state.pc += 2;
    }
}

// OxANNN - Sets I to the address NNN.
- (void)op_0xA___ {
    state.i = state.opcode & 0x0FFF;
    state.pc += 2;
}

// 0xBNNN - Jumps to the address NNN plus V0.
- (void)op_0xB___ {
    state.pc = (state.opcode & 0x0FFF) + state.v[0];
}

// 0xCXNN - Sets VX to a random number and NN.
- (void)op_0xC___ {
    state.v[(state.opcode & 0x0F00) >> 8] = (rand() % 0xFF) & (state.opcode & 0x00FF);
    state.pc += 2;
}

// 0xDXYN - Draws a sprite at coordinate (VX, VY) that has a width of 8 pixels and a height of N
// pixels.  Each row of 8 pixels is read as bit-coded (with the most significant bit of each byte
// displayed on the left) starting from memory location I; I value doesn't change after
// the execution of this instruction. As described above, VF is set to 1 if any screen pixels
// are flipped from set to unset when the sprite is drawn, and to 0 if that doesn't happen.
- (void)op_0xD___ {
    uint16_t x = state.v[(state.opcode & 0x0F00) >> 8];
    uint16_t y = state.v[(state.opcode & 0x00F0) >> 4];
    uint16_t height = state.opcode & 0x000F;
    uint16_t pixel;
    
    state.v[0xF] = 0;
    for (int yline = 0; yline < height; yline++) {
        pixel = state.memory[state.i + yline];
        for(int xline = 0; xline < 8; xline++) {
            if((pixel & (0x80 >> xline)) != 0) {
                if(state.gfx[(x + xline + ((y + yline) * Chip8GraphicsWidth))] == 1) {
                    state.v[0xF] = 1;
                }
                uint8_t xPos = x + xline;
                uint8_t yPos = y + yline;
                uint8_t pVal = state.gfx[xPos + (yPos * Chip8GraphicsWidth)] ^ 1;
                state.gfx[xPos + (yPos * Chip8GraphicsWidth)] = pVal;
                if (self.delegate != nil) {
                    [self.delegate chip8GFXPlotX:xPos Y:yPos Value:pVal];
                }
            }
        }
    }
    state.pc += 2;
}

// 0xE???
- (void)op_0xE___ {
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"op_0xE_%.2X", state.opcode & 0x00FF]);
    if ([self respondsToSelector:selector]) {
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(self, selector);
    }
    else {
        [self.delegate chip8Error:illegalOpcode message:[NSString stringWithFormat:@"illegal opcode: 0x%.4X at 0x%.4X", state.opcode, state.pc]];
        running = NO;
    }
}

// 0xEX9E - Skips the next instruction if the key stored in VX is pressed.
- (void)op_0xE_9E {
    if(state.keys[state.v[(state.opcode & 0x0F00) >> 8]] != 0) {
        state.pc += 4;
    }
    else {
        state.pc += 2;
    }
}

// 0xEXA1 - Skips the next instruction if the key stored in VX isn't pressed.
- (void)op_0xE_A1 {
    if(state.keys[state.v[(state.opcode & 0x0F00) >> 8]] == 0) {
        state.pc += 4;
    }
    else {
        state.pc += 2;
    }
}

// 0xF???
- (void)op_0xF___ {
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"op_0xF_%.2X", state.opcode & 0x00FF]);
    if ([self respondsToSelector:selector]) {
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(self, selector);
    }
    else {
        [self.delegate chip8Error:illegalOpcode message:[NSString stringWithFormat:@"illegal opcode: 0x%.4X at 0x%.4X", state.opcode, state.pc]];
        running = NO;
    }
}

// 0xFX07 - Sets VX to the value of the delay timer.
- (void)op_0xF_07 {
    state.v[(state.opcode & 0x0F00) >> 8] = state.delay_timer;
    state.pc += 2;
}

// 0xFX0A - A key press is awaited, and then stored in VX.
- (void)op_0xF_0A {
    bool keyPress = false;
    for(int i = 0; i < 16; ++i) {
        if(state.keys[i] != 0) {
            state.v[(state.opcode & 0x0F00) >> 8] = i;
            keyPress = true;
        }
    }
    if (keyPress) {
        state.pc += 2;
    }
}

// 0xFX15 - Sets the delay timer to VX.
- (void)op_0xF_15 {
    state.delay_timer = state.v[(state.opcode & 0x0F00) >> 8];
    state.pc += 2;
}

// 0xFX18 - Sets the sound timer to VX.
- (void)op_0xF_18 {
    state.sound_timer = state.v[(state.opcode & 0x0F00) >> 8];
    state.pc += 2;
}

// 0xFX1E - Adds VX to I.
- (void)op_0xF_1E {
    if(state.i + state.v[(state.opcode & 0x0F00) >> 8] > 0xFFF) {
        state.v[0xF] = 1;
    }
    else {
        state.v[0xF] = 0;
    }
    state.i += state.v[(state.opcode & 0x0F00) >> 8];
    state.pc += 2;
}

// 0xFX29 - Sets I to the location of the sprite for the character in VX.
- (void)op_0xF_29 {
    state.i = state.v[(state.opcode & 0x0F00) >> 8] * 0x5;
    state.pc += 2;
}

// 0xFX33 - Stores the Binary-coded decimal representation of VX, with the most
// significant of three digits at the address in I, the middle digit at I plus 1,
// and the least significant digit at I plus 2.
- (void)op_0xF_33 {
    state.memory[state.i] = state.v[(state.opcode & 0x0F00) >> 8] / 100;
    state.memory[state.i + 1] = (state.v[(state.opcode & 0x0F00) >> 8] / 10) % 10;
    state.memory[state.i + 2] = (state.v[(state.opcode & 0x0F00) >> 8] % 100) % 10;
    state.pc += 2;
}

// 0xFX55 - Stores V0 to VX in memory starting at address I.
- (void)op_0xF_55 {
    for (int i = 0; i <= ((state.opcode & 0x0F00) >> 8); ++i) {
        state.memory[state.i + i] = state.v[i];
    }
    state.i += ((state.opcode & 0x0F00) >> 8) + 1;
    state.pc += 2;
}

// 0xFX65 - Fills V0 to VX with values from memory starting at address I.
- (void)op_0xF_65 {
    for (int i = 0; i <= ((state.opcode & 0x0F00) >> 8); ++i) {
        state.v[i] = state.memory[state.i + i];
    }
    state.i += ((state.opcode & 0x0F00) >> 8) + 1;
    state.pc += 2;
}

@end
