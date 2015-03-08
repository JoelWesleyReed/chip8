//
//  Chip8StatePrivate.h
//  Chip8Emulator
//
//  Created by Joel Reed on 3/25/14.
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

#import "Chip8State.h"


@interface Chip8State (private)

- (id)init;
- (void)clearState;
- (void)resetState;
- (void)loadProgram:(NSData*)theProgram;
- (void)dealloc;

@end
