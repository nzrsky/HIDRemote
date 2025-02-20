//
//  DemoController.h
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

#import <Cocoa/Cocoa.h>
#import "HIDRemote.h"

@interface DemoController : NSObject <HIDRemoteDelegate>

#pragma mark -- Remote control code --
- (void)setupRemote;
- (NSString *)buttonNameForButtonCode:(HIDRemoteButtonCode)buttonCode;
- (void)cleanupRemote;

#pragma mark -- UI code --
- (void)addImageNamed:(NSString *)imageName forButtonCode:(HIDRemoteButtonCode)buttonCode;

- (void)appendToLog:(NSString *)logText;
- (void)displayImageForButtonCode:(HIDRemoteButtonCode)buttonCode allowReleaseDisplayDelay:(BOOL)doAllowReleaseDisplayDelay;

- (IBAction)startStopRemote:(id)sender;

- (IBAction)showHideELLCheckbox:(id)sender;
- (IBAction)enableExclusiveLockLending:(id)sender; // Expert option

@end
