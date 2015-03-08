//
//  GFXView.m
//  Chip8GUI
//
//  Created by Joel Reed on 2/25/14.
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

#import "GFXView.h"

static const uint8_t PIXELS_PER_POINT = 8;

@implementation GFXView {
    uint8_t *gfx;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        gfx = malloc(Chip8GraphicsWidth * Chip8GraphicsHeight);
        [self clear];
    }
    return self;
}

- (void)clear
{
    for(int i=0; i<Chip8GraphicsWidth * Chip8GraphicsHeight; i++) {
        gfx[i] = 0x0;
    }
    [self setNeedsDisplay:YES];
}

- (void)plotAtX:(uint8_t)x andY:(uint8_t)y value:(uint8_t)value
{
    gfx[x + (Chip8GraphicsWidth * y)] = value;
    NSRect dirtyRect = NSMakeRect(x * PIXELS_PER_POINT, y * PIXELS_PER_POINT, PIXELS_PER_POINT, PIXELS_PER_POINT);
    [self setNeedsDisplayInRect:dirtyRect];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    uint8_t gfxX = dirtyRect.origin.x / PIXELS_PER_POINT;
    uint8_t gfxY = dirtyRect.origin.y / PIXELS_PER_POINT;
    uint8_t gfxW = dirtyRect.size.width / PIXELS_PER_POINT;
    uint8_t gfxH = dirtyRect.size.height / PIXELS_PER_POINT;
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    for(uint8_t y=gfxY; y<gfxY + gfxH; y++) {
        for(uint8_t x=gfxX; x<gfxX + gfxW; x++) {
            uint16_t gfxIdx = x + (Chip8GraphicsWidth * y);
            uint8_t p = gfx[gfxIdx];
            
            if (p > 0) {
                CGContextSetRGBFillColor(context, 1, 1, 1, 1);
            }
            else {
                CGContextSetRGBFillColor(context, 0, 0, 0, 1);
            }
            CGRect pixel = CGRectMake(x * PIXELS_PER_POINT, y * PIXELS_PER_POINT, PIXELS_PER_POINT, PIXELS_PER_POINT);
            CGContextFillRect(context, pixel);
        }
    }
}

- (void)dealloc
{
    free(gfx);
}

@end
