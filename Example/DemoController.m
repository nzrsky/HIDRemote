//
//  DemoController.m
//  HIDRemoteSample
//
//  Created by Felix Schwarz on 08.10.09.
//  Copyright 2009-2011 IOSPIRIT GmbH. All rights reserved.
//
//  ** LICENSE *************************************************************************
//
//  Copyright (c) 2007-2011 IOSPIRIT GmbH (http://www.iospirit.com/)
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//  
//  * Redistributions of source code must retain the above copyright notice, this list
//    of conditions and the following disclaimer.
//  
//  * Redistributions in binary form must reproduce the above copyright notice, this
//    list of conditions and the following disclaimer in the documentation and/or other
//    materials provided with the distribution.
//  
//  * Neither the name of IOSPIRIT GmbH nor the names of its contributors may be used to
//    endorse or promote products derived from this software without specific prior
//    written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
//  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
//  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
//  DAMAGE.
//
//  ************************************************************************************

#import "DemoController.h"

@implementation DemoController {
    // -- UI --
    IBOutlet NSWindow        *logWindow;
    IBOutlet NSTableView        *logTableView;
    IBOutlet NSArrayController    *logArrayController;
    IBOutlet NSPopUpButton        *modeButton;
    IBOutlet NSButton        *startStopButton;
    IBOutlet NSButton        *enableExclusiveLockLending;
    IBOutlet NSImageView        *statusImageView;
    NSMutableDictionary        *buttonImageMap;
    NSTimeInterval            buttonImageLastShownPress;
    NSTimer                *delayReleaseDisplayTimer;

    // -- HID Remote --
    HIDRemote            *hidRemote;
}

#pragma mark -- Setup --
- (void)awakeFromNib {
	if (!buttonImageMap) {
        if ((buttonImageMap = [[NSMutableDictionary alloc] init]) != nil) {
			[self addImageNamed:@"remoteButtonUp"     forButtonCode:kHIDRemoteButtonCodeUp];
			[self addImageNamed:@"remoteButtonDown"   forButtonCode:kHIDRemoteButtonCodeDown];
			[self addImageNamed:@"remoteButtonLeft"   forButtonCode:kHIDRemoteButtonCodeLeft];
			[self addImageNamed:@"remoteButtonRight"  forButtonCode:kHIDRemoteButtonCodeRight];
			[self addImageNamed:@"remoteButtonSelect" forButtonCode:kHIDRemoteButtonCodeCenter];
			[self addImageNamed:@"remoteButtonMenu"   forButtonCode:kHIDRemoteButtonCodeMenu];
			[self addImageNamed:@"remoteButtonPlay"   forButtonCode:kHIDRemoteButtonCodePlay];
			[self addImageNamed:@"remoteButtonNone"   forButtonCode:kHIDRemoteButtonCodeNone];
		}
	}
	
	// Set up remote control
	[self setupRemote];
	[self appendToLog:@"Launched"];
	[self displayImageForButtonCode:kHIDRemoteButtonCodeNone allowReleaseDisplayDelay:NO];
}

#pragma mark -- Deallocation --
- (void)dealloc {
	[buttonImageMap release];
	buttonImageMap = nil;
	[self cleanupRemote];
	[super dealloc];
}


#pragma mark -- Remote control code --
- (void)setupRemote {
	if (!hidRemote) {
		if ((hidRemote = [[HIDRemote alloc] init]) != nil) {
			[hidRemote setDelegate:self];
		}
	}
}

- (NSString *)buttonNameForButtonCode:(HIDRemoteButtonCode)buttonCode {
	switch (buttonCode) {
		case kHIDRemoteButtonCodeUp:
			return @"Up";
		case kHIDRemoteButtonCodeDown:
			return @"Down";
		case kHIDRemoteButtonCodeLeft:
			return @"Left";
		case kHIDRemoteButtonCodeRight:
			return @"Right";
		case kHIDRemoteButtonCodeCenter:
			return @"Center";
		case kHIDRemoteButtonCodePlay:
			return @"Play/Pause";
		case kHIDRemoteButtonCodeMenu:
			return @"Menu";
		case kHIDRemoteButtonCodeUpHold:
			return @"Up (hold)";
		case kHIDRemoteButtonCodeDownHold:
			return @"Down (hold)";
		case kHIDRemoteButtonCodeLeftHold:
			return @"Left (hold)";
		case kHIDRemoteButtonCodeRightHold:
			return @"Right (hold)";
		case kHIDRemoteButtonCodeCenterHold:
			return @"Center (hold)";
		case kHIDRemoteButtonCodePlayHold:
			return @"Play/Pause (hold)";
		case kHIDRemoteButtonCodeMenuHold:
			return @"Menu (hold)";
		default:;
	}
	
	return ([NSString stringWithFormat:@"Button %x", (int)buttonCode]);
}

- (void)hidRemote:(HIDRemote *)theHidRemote eventWithButton:(HIDRemoteButtonCode)buttonCode isPressed:(BOOL)isPressed fromHardwareWithAttributes:(NSMutableDictionary *)attributes {
	NSString *remoteModel = nil;

	switch ([theHidRemote lastSeenModel]) {
		case kHIDRemoteModelUndetermined:
			remoteModel = [NSString stringWithFormat:@"Undetermined:%d", (int)[theHidRemote lastSeenRemoteControlID]];
		break;

		case kHIDRemoteModelAluminum:
			remoteModel = [NSString stringWithFormat:@"Aluminum:%d", (int)[theHidRemote lastSeenRemoteControlID]];
		break;

		case kHIDRemoteModelWhitePlastic:
			remoteModel = [NSString stringWithFormat:@"White Plastic:%d", (int)[theHidRemote lastSeenRemoteControlID]];
		break;
	}

	if (isPressed) {
		[self appendToLog:[NSString stringWithFormat:@"%@ pressed (%@, %@)", [self buttonNameForButtonCode:buttonCode], remoteModel, attributes[kHIDRemoteProduct]]];
		[self displayImageForButtonCode:buttonCode allowReleaseDisplayDelay:NO];
	} else {
		[self appendToLog:[NSString stringWithFormat:@"%@ released (%@, %@)", [self buttonNameForButtonCode:buttonCode], remoteModel, attributes[kHIDRemoteProduct]]];
		[self displayImageForButtonCode:kHIDRemoteButtonCodeNone allowReleaseDisplayDelay:YES];
	}
}

- (void)cleanupRemote {
	if ([hidRemote isStarted]) {
		[hidRemote stopRemoteControl];
	}

	[hidRemote setDelegate:nil];
	[hidRemote release];
	hidRemote = nil;
}

#pragma mark -- HID Remote code (usage of optional features) --
- (void)hidRemote:(HIDRemote *)aHidRemote remoteIDChangedOldID:(SInt32)old newID:(SInt32)newID forHardwareWithAttributes:(NSMutableDictionary *)attributes {
	[self appendToLog:[NSString stringWithFormat:@"Change of remote ID from %d to %d (for %@ by %@ (Transport: %@))", (int)old, (int)newID, attributes[kHIDRemoteProduct], attributes[kHIDRemoteManufacturer], attributes[kHIDRemoteTransport]]];
}

// Notification about hardware additions/removals 
- (void)hidRemote:(HIDRemote *)aHidRemote foundNewHardwareWithAttributes:(NSMutableDictionary *)attributes {
	[self appendToLog:[NSString stringWithFormat:@"Found hardware: %@ by %@ (Transport: %@)", attributes[kHIDRemoteProduct], attributes[kHIDRemoteManufacturer], attributes[kHIDRemoteTransport]]];
}

- (void)hidRemote:(HIDRemote *)aHidRemote failedNewHardwareWithError:(NSError *)error {
	[self appendToLog:[NSString stringWithFormat:@"Initialization of hardware failed with error %@ (%@)", error.localizedDescription, error.userInfo[@"InternalErrorCode"]]];
}

- (void)hidRemote:(HIDRemote *)aHidRemote releasedHardwareWithAttributes:(NSMutableDictionary *)attributes {
	[self appendToLog:[NSString stringWithFormat:@"Released hardware: %@ by %@ (Transport: %@)", attributes[kHIDRemoteProduct], attributes[kHIDRemoteManufacturer], attributes[kHIDRemoteTransport]]];
}

#pragma mark -- HID Remote code (usage of optional expert, special purpose features) --
- (BOOL)hidRemote:(HIDRemote *)aHidRemote lendExclusiveLockToApplicationWithInfo:(NSDictionary *)applicationInfo {
	[self appendToLog:[NSString stringWithFormat:@"Lending exclusive lock to %@ (pid %@)", applicationInfo[(id)kCFBundleIdentifierKey], applicationInfo[kHIDRemoteDNStatusPIDKey]]];

	return (YES);
}

- (void)hidRemote:(HIDRemote *)aHidRemote exclusiveLockReleasedByApplicationWithInfo:(NSDictionary *)applicationInfo {
	[self appendToLog:[NSString stringWithFormat:@"Exclusive lock released by %@ (pid %@)", applicationInfo[(id)kCFBundleIdentifierKey], applicationInfo[kHIDRemoteDNStatusPIDKey]]];
	[aHidRemote startRemoteControl:kHIDRemoteModeExclusive];
}

- (BOOL)hidRemote:(HIDRemote *)aHidRemote shouldRetryExclusiveLockWithInfo:(NSDictionary *)applicationInfo {
	[self appendToLog:[NSString stringWithFormat:@"%@ (pid %@) says I should retry to acquire exclusive locks", applicationInfo[(id)kCFBundleIdentifierKey], applicationInfo[kHIDRemoteDNStatusPIDKey]]];

	return (YES);
}

#pragma mark -- UI code --
- (void)addImageNamed:(NSString *)imageName forButtonCode:(HIDRemoteButtonCode)buttonCode {
	NSString *imagePath;
	
	if ((imagePath = [[NSBundle mainBundle] pathForImageResource:imageName]) != nil) {
		NSImage *loadedImage;
		
		if ((loadedImage = [[NSImage alloc] initWithContentsOfFile:imagePath]) != nil) {
			buttonImageMap[@((unsigned int)buttonCode)] = loadedImage;
			[loadedImage release];
		}
	}
}

- (void)appendToLog:(NSString *)logText {
	static NSString *timeStampKey = @"timeStamp";
	static NSString *logTextKey   = @"logText";
	[logArrayController addObject:@{timeStampKey: [NSDate date].description, logTextKey: logText}];

    NSInteger rows = (NSInteger)((NSArray *)logArrayController.arrangedObjects).count;
	[logTableView scrollRowToVisible:rows - 1];
}

- (void)displayImageForButtonCode:(HIDRemoteButtonCode)buttonCode allowReleaseDisplayDelay:(BOOL)doAllowReleaseDisplayDelay {
	HIDRemoteButtonCode basicCode;
	NSImage *image;
	
	if (delayReleaseDisplayTimer) {
		[delayReleaseDisplayTimer invalidate];
		[delayReleaseDisplayTimer release];
		delayReleaseDisplayTimer = nil;
	}
	
	if (buttonCode == kHIDRemoteButtonCodeNone) {
		if (doAllowReleaseDisplayDelay && (buttonImageLastShownPress != 0.0)) {
			if (([NSDate timeIntervalSinceReferenceDate] - buttonImageLastShownPress) < 0.10) {
				delayReleaseDisplayTimer = [[NSTimer scheduledTimerWithTimeInterval:0.10 target:self selector:@selector(displayDefaultImage:) userInfo:nil repeats:NO] retain];
				return;
			}
		}
	}
	else
	{
		buttonImageLastShownPress = [NSDate timeIntervalSinceReferenceDate];
	}

	basicCode = buttonCode & kHIDRemoteButtonCodeCodeMask;

	if ((image = buttonImageMap[@(basicCode)]) != nil) {
		statusImageView.image = image;
	}
}

- (void)displayDefaultImage:(NSTimer *)aTimer
{
	[self displayImageForButtonCode:kHIDRemoteButtonCodeNone allowReleaseDisplayDelay:NO];
}

- (IBAction)startStopRemote:(id)sender {
	// Has the HID Remote already been started?
	if ([hidRemote isStarted]) {
		// HID Remote already started. Stop it.
		[hidRemote stopRemoteControl];
		startStopButton.title = @"Start";
		[modeButton setEnabled:YES];
		[self appendToLog:@"-- Stopped HID Remote --"];
	} else {
		// HID Remote has not been started yet. Start it.
		HIDRemoteMode remoteMode = kHIDRemoteModeNone;
		NSString *remoteModeName = nil;
		
		// Fancy GUI stuff
		switch (modeButton.indexOfSelectedItem) {
			case 0:
				remoteMode = kHIDRemoteModeShared;
				remoteModeName = @"shared";
			break;

			case 1:
				remoteMode = kHIDRemoteModeExclusive;
				remoteModeName = @"exclusive";
			break;

			case 2:
				remoteMode = kHIDRemoteModeExclusiveAuto;
				remoteModeName = @"exclusive (auto)";
			break;
		}
	
		// Check whether the installation of Candelair is required to reliably operate in this mode
		if ([HIDRemote isCandelairInstallationRequiredForRemoteMode:remoteMode]) {
			// Reliable usage of the remote in this mode under this operating system version
			// requires the Candelair driver to be installed. Tell the user about it.
			#pragma clang diagnostic push
			#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			NSAlert *alert;
			
			if ((alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Candelair driver installation necessary", @"")
			                             defaultButton:NSLocalizedString(@"Download", @"")
						   alternateButton:NSLocalizedString(@"More information", @"")
						       otherButton:NSLocalizedString(@"Cancel", @"")
					 informativeTextWithFormat:NSLocalizedString(@"An additional driver needs to be installed before %@ can reliably access the remote under the OS version installed on your computer.", @""), [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleNameKey]]) != nil) {
				switch ([alert runModal]) {
					case NSAlertDefaultReturn:
						[[NSWorkspace sharedWorkspace] openURL:(NSURL * _Nonnull)[NSURL URLWithString:@"http://www.candelair.com/download/"]];
					break;

					case NSAlertAlternateReturn:
						[[NSWorkspace sharedWorkspace] openURL:(NSURL * _Nonnull)[NSURL URLWithString:@"http://www.candelair.com/"]];
					break;
				}
			}
			#pragma clang diagnostic pop
		} else {
			// Candelair is either already installed or not required under this OS release => proceed!
			if ([hidRemote startRemoteControl:remoteMode]) {
				// Start was successful, perform UI changes and log it.
				[self appendToLog:[NSString stringWithFormat:@"-- Starting HID Remote in %@ mode (OS X %lx) successful --", remoteModeName, (unsigned long)[HIDRemote OSXVersion]]];
				startStopButton.title = @"Stop";
				[modeButton setEnabled:NO];
			} else {
				// Start failed. Log about it
				[self appendToLog:[NSString stringWithFormat:@"Starting HID Remote in %@ mode failed", remoteModeName]];
			}
		}
	}
}

- (BOOL)windowShouldClose:(id)window {
	[[NSApplication sharedApplication] terminate:self];
	return (YES);
}

- (IBAction)showHideELLCheckbox:(id)sender {
	// Exclusive mode selected
	if (modeButton.indexOfSelectedItem == 1) {
		[enableExclusiveLockLending setHidden:NO];
	} else {
		[enableExclusiveLockLending setHidden:YES];
	}
}

- (IBAction)enableExclusiveLockLending:(NSButton *)sender {
    if (sender.state == NSControlStateValueOn) {
		[self appendToLog:@"Exclusive Lock Lending enabled"];
		[hidRemote setExclusiveLockLendingEnabled:YES];
	} else {
		[self appendToLog:@"Exclusive Lock Lending disabled"];
		[hidRemote setExclusiveLockLendingEnabled:NO];
	}
}

@end
