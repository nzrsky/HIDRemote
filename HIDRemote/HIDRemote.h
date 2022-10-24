//
//  HIDRemote.m
//  HIDRemote V1.7 (5th September 2018)
//
//  Created by Felix Schwarz on 06.04.07.
//  Copyright 2007-2018 IOSPIRIT GmbH. All rights reserved.
//
//  The latest version of this class is available at
//     http://www.iospirit.com/developers/hidremote/
//
//  ** LICENSE *************************************************************************
//
//  Copyright (c) 2007-2017 IOSPIRIT GmbH (http://www.iospirit.com/)
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

//  ************************************************************************************
//  ********************************** DOCUMENTATION ***********************************
//  ************************************************************************************
//
//  - a reference is available at http://www.iospirit.com/developers/hidremote/reference/
//  - for a guide, please see http://www.iospirit.com/developers/hidremote/guide/
//
//  ************************************************************************************

@import Foundation;
@import Cocoa;
@import IOKit;
#include <unistd.h>
#include <mach/mach.h>
#include <sys/types.h>

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
#warning Minimal macOS version is 10.10
#endif

#ifndef HIDREMOTE_THREADSAFETY_HARDENED_NOTIFICATION_HANDLING
#define HIDREMOTE_THREADSAFETY_HARDENED_NOTIFICATION_HANDLING 1
#endif

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Driver compatibility flags
#ifndef HID_REMOTE_COMPATIBILITY_FLAGS_ENUM
#define HID_REMOTE_COMPATIBILITY_FLAGS_ENUM 1
typedef NS_CLOSED_ENUM(unsigned int, HIDRemoteCompatibilityFlags) {
    kHIDRemoteCompatibilityFlagsStandardHIDRemoteDevice = 1L,
};
#endif /* HID_REMOTE_COMPATIBILITY_FLAGS_ENUM */

#pragma mark - Enums / Codes

#ifndef HID_REMOTE_MODE_ENUM
#define HID_REMOTE_MODE_ENUM 1

typedef NS_CLOSED_ENUM(NSUInteger, HIDRemoteMode) {
    kHIDRemoteModeNone = 0L,
    kHIDRemoteModeShared,		// Share the remote with others - let's you listen to the remote control events as long as noone has an exclusive lock on it
    // (RECOMMENDED ONLY FOR SPECIAL PURPOSES)

    kHIDRemoteModeExclusive,	// Try to acquire an exclusive lock on the remote (NOT RECOMMENDED)

    kHIDRemoteModeExclusiveAuto	// Try to acquire an exclusive lock on the remote whenever the application has focus. Temporarily release control over the
    // remote when another application has focus (RECOMMENDED)
};

#endif /* HID_REMOTE_MODE_ENUM */

typedef NS_OPTIONS(NSUInteger, HIDRemoteButtonCode) {
    /* A code reserved for "no button" (needed for tracking) */
    kHIDRemoteButtonCodeNone	= 0L,

    /* Standard codes - available for white plastic and aluminum remote */
    kHIDRemoteButtonCodeUp,
    kHIDRemoteButtonCodeDown,
    kHIDRemoteButtonCodeLeft,
    kHIDRemoteButtonCodeRight,
    kHIDRemoteButtonCodeCenter,
    kHIDRemoteButtonCodeMenu,

    /* Extra codes - Only available for the new aluminum version of the remote */
    kHIDRemoteButtonCodePlay,

    /* Masks */
    kHIDRemoteButtonCodeCodeMask      = 0xFFL,
    kHIDRemoteButtonCodeHoldMask      = (1L << 16L),
    kHIDRemoteButtonCodeSpecialMask   = (1L << 17L),
    kHIDRemoteButtonCodeAluminumMask  = (1L << 21L), // PRIVATE - only used internally

    /* Hold button standard codes - available for white plastic and aluminum remote */
    kHIDRemoteButtonCodeUpHold       = (kHIDRemoteButtonCodeHoldMask|kHIDRemoteButtonCodeUp),
    kHIDRemoteButtonCodeDownHold     = (kHIDRemoteButtonCodeHoldMask|kHIDRemoteButtonCodeDown),
    kHIDRemoteButtonCodeLeftHold     = (kHIDRemoteButtonCodeHoldMask|kHIDRemoteButtonCodeLeft),
    kHIDRemoteButtonCodeRightHold    = (kHIDRemoteButtonCodeHoldMask|kHIDRemoteButtonCodeRight),
    kHIDRemoteButtonCodeCenterHold	 = (kHIDRemoteButtonCodeHoldMask|kHIDRemoteButtonCodeCenter),
    kHIDRemoteButtonCodeMenuHold	 = (kHIDRemoteButtonCodeHoldMask|kHIDRemoteButtonCodeMenu),

    /* Hold button extra codes - Only available for aluminum version of the remote */
    kHIDRemoteButtonCodePlayHold	  = (kHIDRemoteButtonCodeHoldMask|kHIDRemoteButtonCodePlay),

    /* DEPRECATED codes - compatibility with HIDRemote 1.0 */
    kHIDRemoteButtonCodePlus	      = kHIDRemoteButtonCodeUp,
    kHIDRemoteButtonCodePlusHold      = kHIDRemoteButtonCodeUpHold,
    kHIDRemoteButtonCodeMinus	      = kHIDRemoteButtonCodeDown,
    kHIDRemoteButtonCodeMinusHold     = kHIDRemoteButtonCodeDownHold,
    kHIDRemoteButtonCodePlayPause	  = kHIDRemoteButtonCodeCenter,
    kHIDRemoteButtonCodePlayPauseHold = kHIDRemoteButtonCodeCenterHold,

    /* Special purpose codes */
    kHIDRemoteButtonCodeIDChanged  = (kHIDRemoteButtonCodeSpecialMask|(1L << 18L)),	// (the ID of the connected remote has changed, you can safely ignore this)
#ifdef _HIDREMOTE_EXTENSIONS
#define _HIDREMOTE_EXTENSIONS_SECTION 1
#include "HIDRemoteAdditions.h"
#undef _HIDREMOTE_EXTENSIONS_SECTION
#endif /* _HIDREMOTE_EXTENSIONS */
};

typedef NS_CLOSED_ENUM(NSUInteger, HIDRemoteModel) {
    kHIDRemoteModelUndetermined = 0L,				// Assume a white plastic remote
    kHIDRemoteModelWhitePlastic,					// Signal *likely* to be coming from a white plastic remote
    kHIDRemoteModelAluminum						// Signal *definitely* coming from an aluminum remote
};

typedef NS_CLOSED_ENUM(NSUInteger, HIDRemoteAluminumRemoteSupportLevel) {
    kHIDRemoteAluminumRemoteSupportLevelNone = 0L,			// This system has no support for the Aluminum Remote at all
    kHIDRemoteAluminumRemoteSupportLevelEmulation,			// This system possibly has support for the Aluminum Remote (via emulation)
    kHIDRemoteAluminumRemoteSupportLevelNative			// This system has native support for the Aluminum Remote
};

typedef NSDictionary<NSString *, id> HIDServiceAttributes;
typedef NSMutableDictionary<NSString *, id> MutableHIDServiceAttributes;

typedef NSMutableDictionary<NSNumber *, HIDServiceAttributes *> HIDServicesMap;
typedef NSArray<NSNumber *> HIDRemoteButtonCodesList;

@protocol HIDRemoteDelegate;

#pragma mark - Actual header file for class
@interface HIDRemote : NSObject

@property (nonatomic, readonly, class) HIDRemote *sharedHIDRemote;

@property (nonatomic, readonly, class) BOOL isCandelairInstalled;
@property (nonatomic, readonly, class) SInt32 OSXVersion;

+ (BOOL)isCandelairInstallationRequiredForRemoteMode:(HIDRemoteMode)remoteMode;

@property (nonatomic, weak, nullable) NSObject<HIDRemoteDelegate> *delegate;
@property (nonatomic, readonly) HIDRemoteAluminumRemoteSupportLevel aluminiumRemoteSystemSupportLevel;

@property (nonatomic, readonly) BOOL isStarted;
@property (nonatomic, readonly) HIDRemoteMode startedInMode;
@property (nonatomic, readonly) NSUInteger activeRemoteControlCount;
@property (nonatomic, readonly) SInt32 lastSeenRemoteControlID;
@property (nonatomic) HIDRemoteModel lastSeenModel;

@property (nonatomic) BOOL simulateHoldEvents;
@property (nonatomic, copy) HIDRemoteButtonCodesList *unusedButtonCodes;

- (BOOL)startRemoteControl:(HIDRemoteMode)mode;
- (void)stopRemoteControl;

// Expert APIs
@property (nonatomic) BOOL enableSecureEventInputWorkaround;
@property (nonatomic) BOOL exclusiveLockLendingEnabled;

@property (nonatomic, readonly) BOOL isApplicationTerminating;
@property (nonatomic, readonly) BOOL isStopping;

@end


@protocol HIDRemoteDelegate

@required
// Notification of button events
- (void)hidRemote:(HIDRemote *)hidRemote eventWithButton:(HIDRemoteButtonCode)buttonCode isPressed:(BOOL)isPressed fromHardwareWithAttributes:(HIDServiceAttributes *)attributes;

@optional
// Notification of ID changes
// Invoked when the user switched to a remote control with a different ID
- (void)hidRemote:(HIDRemote *)hidRemote remoteIDChangedOldID:(SInt32)old newID:(SInt32)newID forHardwareWithAttributes:(HIDServiceAttributes *)attributes;

// Notification about hardware additions/removals
// Invoked when new hardware was found / added to HIDRemote's pool
- (void)hidRemote:(HIDRemote *)hidRemote foundNewHardwareWithAttributes:(HIDServiceAttributes *)attributes;

// Invoked when initialization of new hardware as requested failed
- (void)hidRemote:(HIDRemote *)hidRemote failedNewHardwareWithError:(NSError * _Nullable)error;

// Invoked when hardware was removed from HIDRemote's pool
- (void)hidRemote:(HIDRemote *)hidRemote releasedHardwareWithAttributes:(HIDServiceAttributes *)attributes;

// ### WARNING: Unless you know VERY PRECISELY what you are doing, do not implement any of the delegate methods below. ###

// Matching of newly found receiver hardware. Invoked when new hardware is inspected
// Return YES if HIDRemote should go on with this hardware and try to use it, or NO if it should not be persued further.
- (BOOL)hidRemote:(HIDRemote *)hidRemote inspectNewHardwareWithService:(io_service_t)service prematchResult:(BOOL)prematchResult;

// Exlusive lock lending
- (BOOL)hidRemote:(HIDRemote *)hidRemote lendExclusiveLockToApplicationWithInfo:(HIDServiceAttributes *)applicationInfo;
- (void)hidRemote:(HIDRemote *)hidRemote exclusiveLockReleasedByApplicationWithInfo:(HIDServiceAttributes *)applicationInfo;
- (BOOL)hidRemote:(HIDRemote *)hidRemote shouldRetryExclusiveLockWithInfo:(HIDServiceAttributes *)applicationInfo;

@end

#pragma mark - Information attribute keys
extern NSString *kHIDRemoteManufacturer;
extern NSString *kHIDRemoteProduct;
extern NSString *kHIDRemoteTransport;

#pragma mark - Internal/Expert attribute keys (AKA: don't touch these unless you really, really, REALLY know what you do)
extern NSString *kHIDRemoteCFPluginInterface;
extern NSString *kHIDRemoteHIDDeviceInterface;
extern NSString *kHIDRemoteCookieButtonCodeLUT;
extern NSString *kHIDRemoteHIDQueueInterface;
extern NSString *kHIDRemoteServiceNotification;
extern NSString *kHIDRemoteCFRunLoopSource;
extern NSString *kHIDRemoteLastButtonPressed;
extern NSString *kHIDRemoteService;
extern NSString *kHIDRemoteSimulateHoldEventsTimer;
extern NSString *kHIDRemoteSimulateHoldEventsOriginButtonCode;
extern NSString *kHIDRemoteAluminumRemoteSupportLevel;
extern NSString *kHIDRemoteAluminumRemoteSupportOnDemand;

#pragma mark - Distributed notifications
extern NSString *kHIDRemoteDNHIDRemotePing;
extern NSString *kHIDRemoteDNHIDRemoteRetry;
extern NSString *kHIDRemoteDNHIDRemoteStatus;

extern NSString *kHIDRemoteDNHIDRemoteRetryGlobalObject;

#pragma mark - Distributed notifications userInfo keys and values
extern NSString *kHIDRemoteDNStatusHIDRemoteVersionKey;
extern NSString *kHIDRemoteDNStatusPIDKey;
extern NSString *kHIDRemoteDNStatusModeKey;
extern NSString *kHIDRemoteDNStatusUnusedButtonCodesKey;
extern NSString *kHIDRemoteDNStatusRemoteControlCountKey;
extern NSString *kHIDRemoteDNStatusReturnToPIDKey;
extern NSString *kHIDRemoteDNStatusActionKey;
extern NSString *kHIDRemoteDNStatusActionStart;
extern NSString *kHIDRemoteDNStatusActionStop;
extern NSString *kHIDRemoteDNStatusActionUpdate;
extern NSString *kHIDRemoteDNStatusActionNoNeed;

NS_ASSUME_NONNULL_END
