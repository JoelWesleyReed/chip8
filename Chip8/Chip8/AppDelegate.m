//
//  AppDelegate.m
//  Chip8
//
//  Created by Joel Reed on 3/4/14.
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

#import "AppDelegate.h"


@implementation AppDelegate {
    Chip8Emulator *em;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.window setDelegate:self];
    
    [self.menuProgramRun setEnabled:NO];
    [self.menuProgramStep setEnabled:NO];
    [self.menuProgramStop setEnabled:NO];
    [self.menuProgramReset setEnabled:NO];
    [self.tbRun setEnabled:NO];
    [self.tbStep setEnabled:NO];
    [self.tbStop setEnabled:NO];
    [self.tbReset setEnabled:NO];
    
    for(int r=0; r<2; r++) {
        for(int c=0; c<8; c++) {
            [[self.keyMatrix cellAtRow:r column:c] sendActionOn:NSLeftMouseDownMask | NSLeftMouseUpMask];
        }
    }
    
    [self.labelCycleOverflow setHidden:YES];
    
    em = [[Chip8Emulator alloc] initWithDelegate:self];
}

#pragma mark - NSWindow Delegates

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    if ([em running]) {
        [em stop];
    }
}

#pragma mark - IB Actions

- (IBAction)open:(id)sender {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    openPanel.title = @"Choose a Chip8 Program file";
    openPanel.showsResizeIndicator = YES;
    openPanel.showsHiddenFiles = NO;
    openPanel.canChooseDirectories = NO;
    openPanel.canCreateDirectories = NO;
    openPanel.allowsMultipleSelection = NO;
    openPanel.allowedFileTypes = @[@"ch8"];
    
    BOOL wasRunning = NO;
    if ([em running]) {
        wasRunning = YES;
        [em stop];
    }
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result==NSOKButton) {
            NSURL *selection = openPanel.URLs[0];
            NSString* path = [selection.path stringByResolvingSymlinksInPath];
            NSData *theProgram = [NSData dataWithContentsOfFile:path];
            [em load:theProgram];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *fileName = [[path lastPathComponent] stringByDeletingPathExtension];
                [self.window setTitle:[NSString stringWithFormat:@"Chip8 - %@", fileName]];
                
                [self.gfxView clear];
                
                [self.menuProgramRun setEnabled:YES];
                [self.menuProgramStep setEnabled:YES];
                [self.menuProgramStop setEnabled:NO];
                [self.menuProgramReset setEnabled:YES];
                [self.tbRun setEnabled:YES];
                [self.tbStep setEnabled:YES];
                [self.tbStop setEnabled:NO];
                [self.tbReset setEnabled:YES];
            });
        }
        else {
            if (wasRunning) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    [em run];
                });
            }
        }
    }];
}

- (IBAction)toggleState:(id)sender {
    if ([self.stateDrawer state] == NSDrawerClosedState) {
        [self.stateDrawer toggle:self.window];
        [self.menuViewToggleState setState:YES];
    }
    else {
        [self.stateDrawer toggle:self.window];
        [self.menuViewToggleState setState:NO];
    }
}

- (IBAction)run:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [em run];
    });
}

- (IBAction)step:(id)sender {
    [em step];
}

- (IBAction)stop:(id)sender {
    [em stop];
}

- (IBAction)reset:(id)sender {
    [em reset];
}

- (IBAction)speedChanged:(id)sender {
    [em setClockSpeedHz:[sender integerValue]];
}

- (IBAction)keyPressed:(id)sender {
    NSButton *selectedButton = [sender selectedCell];
    
    NSScanner *scanner = [NSScanner scannerWithString:[selectedButton title]];
    uint32_t button = 0x0;
    [scanner scanHexInt:&button];
    
    if ([selectedButton state] == NSOnState) {
        [em buttonPress:button];
    }
    else {
        [em buttonRelease:button];
    }
    
    [selectedButton setState:NSOffState];
}

#pragma mark - Chip8 Emulator Delegates

- (BOOL)chip8StartRequested {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.menuProgramRun setEnabled:NO];
        [self.menuProgramStep setEnabled:NO];
        [self.menuProgramStop setEnabled:YES];
        [self.menuProgramReset setEnabled:YES];
        [self.tbRun setEnabled:NO];
        [self.tbStep setEnabled:NO];
        [self.tbStop setEnabled:YES];
        [self.tbReset setEnabled:YES];
    });
    return YES;
}

- (void)chip8StartComplete {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.runningIndicator startAnimation:self];
    });
}

- (BOOL)chip8StopRequested {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.menuProgramRun setEnabled:YES];
        [self.menuProgramStep setEnabled:YES];
        [self.menuProgramStop setEnabled:NO];
        [self.menuProgramReset setEnabled:YES];
        [self.tbRun setEnabled:YES];
        [self.tbStep setEnabled:YES];
        [self.tbStop setEnabled:NO];
        [self.tbReset setEnabled:YES];
    });
    return YES;
}

- (void)chip8StopComplete {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.runningIndicator stopAnimation:self];
    });
}

- (void)chip8GFXPlotX:(uint8_t)x Y:(uint8_t)y Value:(uint8_t)value {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gfxView plotAtX:x andY:y value:value];
    });
}

- (void)chip8Error:(Chip8ErrorId)errorId message:(NSString*)errorMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.menuProgramRun setEnabled:YES];
        [self.menuProgramStep setEnabled:YES];
        [self.menuProgramStop setEnabled:NO];
        [self.menuProgramReset setEnabled:YES];
        [self.tbRun setEnabled:YES];
        [self.tbStep setEnabled:YES];
        [self.tbStop setEnabled:NO];
        [self.tbReset setEnabled:YES];
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:[NSString stringWithFormat:@"Error: [%lu]-%@", errorId, errorMessage]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
    });
}

- (void)chip8CycleTimeOverflow:(double)theAmount {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.labelCycleOverflow isHidden] == YES) {
            [self.labelCycleOverflow setHidden:NO];
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self.labelCycleOverflow setHidden:YES];
            });
        }
    });
}

#pragma mark - Chip8 State Delegate

- (void)chip8State:(Chip8State *)theState {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.statePC setStringValue:[NSString stringWithFormat:@"%.4X", theState.pc]];
        
        for(int i=0; i<5; i++) {
            uint16_t address = theState.pc + (i - 2) * 2;
            if (address >= Chip8ProgramLocation && address <= Chip8MemorySize) {
                uint16_t value = theState.memory[address] << 8 | theState.memory[address + 1];
                [[self.stateProgMatrix cellAtRow:0 column:i] setStringValue:[NSString stringWithFormat:@"%.4X", value]];
            }
            else {
                [[self.stateProgMatrix cellAtRow:0 column:i] setStringValue:@"----"];
            }
        }
        
        for(int r=0; r<4; r++) {
            for(int c=0; c<4; c++) {
                uint8_t reg = r + (c * 4);
                [[self.stateRegMatrix cellAtRow:r column:c] setStringValue:[NSString stringWithFormat:@"%.2X", theState.v[reg]]];
            }
        }
        
        [self.stateRegI setStringValue:[NSString stringWithFormat:@"%.4X", theState.i]];
        
        for(int r=0; r<4; r++) {
            for(int c=0; c<4; c++) {
                uint8_t key = r + (c * 4);
                [[self.stateKeyMatrix cellAtRow:r column:c] setStringValue:[NSString stringWithFormat:@"%.2X", theState.keys[key]]];
            }
        }
        
        [self.stateDelay setStringValue:[NSString stringWithFormat:@"%.2X", theState.delay_timer]];
        [self.stateSound setStringValue:[NSString stringWithFormat:@"%.2X", theState.sound_timer]];
        
        for(int i=0; i<9; i++) {
            int pos = (int)theState.sp - (i + 1);
            if (pos >= 0) {
                [[self.stateStackLabelMatrix cellAtRow:i column:0] setStringValue:[NSString stringWithFormat:@"%X:", pos]];
                [[self.stateStackValueMatrix cellAtRow:i column:0] setStringValue:[NSString stringWithFormat:@"%.4X", theState.stack[pos]]];
            }
            else {
                [[self.stateStackLabelMatrix cellAtRow:i column:0] setStringValue:@"-:"];
                [[self.stateStackValueMatrix cellAtRow:i column:0] setStringValue:@"----"];
            }
        }
     });
}

@end
