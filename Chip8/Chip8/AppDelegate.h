//
//  AppDelegate.h
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

#import <Cocoa/Cocoa.h>

#import "GFXView.h"


@interface AppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate,Chip8EmulatorDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSMenuItem *menuFileOpen;
@property (weak) IBOutlet NSMenuItem *menuProgramRun;
@property (weak) IBOutlet NSMenuItem *menuProgramStep;
@property (weak) IBOutlet NSMenuItem *menuProgramStop;
@property (weak) IBOutlet NSMenuItem *menuProgramReset;
@property (weak) IBOutlet NSMenuItem *menuViewToggleState;

@property (weak) IBOutlet NSToolbarItem *tbOpen;
@property (weak) IBOutlet NSToolbarItem *tbRun;
@property (weak) IBOutlet NSToolbarItem *tbStep;
@property (weak) IBOutlet NSToolbarItem *tbStop;
@property (weak) IBOutlet NSToolbarItem *tbReset;
@property (weak) IBOutlet NSToolbarItem *tbToggleState;

@property (weak) IBOutlet GFXView *gfxView;

@property (weak) IBOutlet NSMatrix *keyMatrix;

@property (weak) IBOutlet NSDrawer *stateDrawer;
@property (weak) IBOutlet NSTextField *statePC;
@property (weak) IBOutlet NSMatrix *stateProgMatrix;
@property (weak) IBOutlet NSMatrix *stateRegMatrix;
@property (weak) IBOutlet NSTextField *stateRegI;
@property (weak) IBOutlet NSMatrix *stateKeyMatrix;
@property (weak) IBOutlet NSTextField *stateDelay;
@property (weak) IBOutlet NSTextField *stateSound;
@property (weak) IBOutlet NSMatrix *stateStackLabelMatrix;
@property (weak) IBOutlet NSMatrix *stateStackValueMatrix;

@property (weak) IBOutlet NSProgressIndicator *runningIndicator;
@property (weak) IBOutlet NSTextField *labelCycleOverflow;

- (IBAction)open:(id)sender;
- (IBAction)toggleState:(id)sender;

- (IBAction)run:(id)sender;
- (IBAction)step:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)reset:(id)sender;

- (IBAction)speedChanged:(id)sender;
- (IBAction)keyPressed:(id)sender;

@end
