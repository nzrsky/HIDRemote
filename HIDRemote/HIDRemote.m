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

#import "HIDRemote.h"

NS_ASSUME_NONNULL_BEGIN

#if !defined(let)
    #define let __auto_type const
#endif

#if !defined(var)
    #define var __auto_type
#endif

// Attribute dictionary keys
NSString *kHIDRemoteCFPluginInterface              = @"CFPluginInterface";
NSString *kHIDRemoteHIDDeviceInterface             = @"HIDDeviceInterface";
NSString *kHIDRemoteCookieButtonCodeLUT            = @"CookieButtonCodeLUT";
NSString *kHIDRemoteHIDQueueInterface              = @"HIDQueueInterface";
NSString *kHIDRemoteServiceNotification            = @"ServiceNotification";
NSString *kHIDRemoteCFRunLoopSource                = @"CFRunLoopSource";
NSString *kHIDRemoteLastButtonPressed              = @"LastButtonPressed";
NSString *kHIDRemoteService                        = @"Service";
NSString *kHIDRemoteSimulateHoldEventsTimer        = @"SimulateHoldEventsTimer";
NSString *kHIDRemoteSimulateHoldEventsOriginButtonCode    = @"SimulateHoldEventsOriginButtonCode";
NSString *kHIDRemoteAluminumRemoteSupportLevel    = @"AluminumRemoteSupportLevel";
NSString *kHIDRemoteAluminumRemoteSupportOnDemand = @"AluminumRemoteSupportLevelOnDemand";

NSString *kHIDRemoteManufacturer                  = @"Manufacturer";
NSString *kHIDRemoteProduct                       = @"Product";
NSString *kHIDRemoteTransport                     = @"Transport";

// Distributed notifications
NSString *kHIDRemoteDNHIDRemotePing               = @"com.candelair.ping";
NSString *kHIDRemoteDNHIDRemoteRetry              = @"com.candelair.retry";
NSString *kHIDRemoteDNHIDRemoteStatus             = @"com.candelair.status";

NSString *kHIDRemoteDNHIDRemoteRetryGlobalObject  = @"global";

// Distributed notifications userInfo keys and values
NSString *kHIDRemoteDNStatusHIDRemoteVersionKey   = @"HIDRemoteVersion";
NSString *kHIDRemoteDNStatusPIDKey                = @"PID";
NSString *kHIDRemoteDNStatusModeKey               = @"Mode";
NSString *kHIDRemoteDNStatusUnusedButtonCodesKey  = @"UnusedButtonCodes";
NSString *kHIDRemoteDNStatusActionKey             = @"Action";
NSString *kHIDRemoteDNStatusRemoteControlCountKey = @"RemoteControlCount";
NSString *kHIDRemoteDNStatusReturnToPIDKey        = @"ReturnToPID";
NSString *kHIDRemoteDNStatusActionStart           = @"start";
NSString *kHIDRemoteDNStatusActionStop            = @"stop";
NSString *kHIDRemoteDNStatusActionUpdate          = @"update";
NSString *kHIDRemoteDNStatusActionNoNeed          = @"noneed";

// Callback Prototypes
static void HIDEventCallback(void *target, IOReturn result, void *refcon, void *sender);
static void ServiceMatchingCallback(void *refCon, io_iterator_t iterator);
static void ServiceNotificationCallback(void *refCon, io_service_t service, natural_t messageType, void *messageArgument);
static void SecureInputNotificationCallback(void *refCon, io_service_t service, natural_t messageType, void *messageArgument);

static NSString * const kAppleIRController = @"AppleIRController";
static NSString * const kRBIOKitAIREmu = @"RBIOKitAIREmu";
static NSString * const kIOSPIRITIRController = @"IOSPIRITIRController";

static CFStringRef const kCandelairHIDRemoteCompatibilityDevice = CFSTR("CandelairHIDRemoteCompatibilityDevice");
static CFStringRef const kCandelairHIDRemoteCompatibilityMask = CFSTR("CandelairHIDRemoteCompatibilityMask");

static CFStringRef const kEnableAluminumRemoteSupportForMe = CFSTR("EnableAluminumRemoteSupportForMe");
static CFStringRef const kIOConsoleUsers = CFSTR("IOConsoleUsers");

static NSString * const kCGSSessionSecureInputPID = @"kCGSSessionSecureInputPID";
static NSString * const kCGSSessionOnConsoleKey = @"kCGSSessionOnConsoleKey";
static NSString * const kCGSSessionUserIDKey = @"kCGSSessionUserIDKey";
static NSString * const CGSSessionScreenIsLocked = @"CGSSessionScreenIsLocked";

@interface HIDRemote ()
#pragma mark - PRIVATE: HID Event handling
- (void)_handleButtonCode:(HIDRemoteButtonCode)buttonCode isPressed:(BOOL)isPressed attributes:(MutableHIDServiceAttributes *)hidAttribsDict;
- (void)_sendButtonCode:(HIDRemoteButtonCode)buttonCode isPressed:(BOOL)isPressed attributes:(HIDServiceAttributes *)hidAttribsDict;
- (void)_hidEventFor:(io_service_t)hidDevice from:(IOHIDQueueInterface **)interface withResult:(IOReturn)result;

#pragma mark - PRIVATE: Service setup and destruction
- (BOOL)_prematchService:(io_object_t)service;
- (HIDRemoteButtonCode)buttonCodeForUsage:(NSUInteger)usage usagePage:(NSUInteger)usagePage;
- (BOOL)_setupService:(io_object_t)service;
- (void)_destructService:(io_object_t)service;

#pragma mark - PRIVATE: Distributed notifiations handling
- (void)_postStatusWithAction:(NSString *)action;
- (void)_handleNotifications:(NSNotification *)notification;

#pragma mark - PRIVATE: Application becomes active / inactive handling for kHIDRemoteModeExclusiveAuto
- (void)_appStatusChanged:(NSNotification *)notification;
- (void)_delayedAutoRecovery:(NSTimer *)aTimer;

#pragma mark - PRIVATE: Notification handling
- (void)_serviceMatching:(io_iterator_t)iterator;
- (void)_serviceNotificationFor:(io_service_t)service messageType:(natural_t)messageType messageArgument:(void *)messageArgument;
- (void)_updateSessionInformation;
- (void)_secureInputNotificationFor:(io_service_t)service messageType:(natural_t)messageType messageArgument:(void *)messageArgument;
@end

@implementation HIDRemote {
    mach_port_t _masterPort;
    IONotificationPortRef _notifyPort;
    CFRunLoopSourceRef _notifyRLSource;
    io_iterator_t _matchingServicesIterator;
    io_object_t _secureInputNotification;
    HIDServicesMap *_servicesMap;

    HIDRemoteMode _mode;
    BOOL _autoRecover;
    NSTimer *_autoRecoveryTimer;

    SInt32 _lastSeenRemoteID;
    SInt32 _lastSeenModelRemoteID;

    NSUInteger _lastSecureEventInputPIDSum;
    uid_t _lastFrontUserSession;
    BOOL _lastScreenIsLocked;

    BOOL _sendExclusiveResourceReuseNotification;
    NSNumber *_waitForReturnByPID;
    NSNumber *_returnToPID;
    BOOL _isRestarting;

    BOOL _sendStatusNotifications;
    NSString *_pidString;

    /*
        #define HIDREMOTE_THREADSAFETY_HARDENED_NOTIFICATION_HANDLING if you're running your HIDRemote
        instance on a background thread (requires OS X 10.5 or later)
    */
    #if HIDREMOTE_THREADSAFETY_HARDENED_NOTIFICATION_HANDLING
        // Thread safety
        NSThread *_runOnThread;
    #endif
}

@synthesize startedInMode = _mode;

#pragma mark - Init, dealloc & shared instance

+ (instancetype)sharedHIDRemote {
    static HIDRemote *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HIDRemote alloc] init];
    });
	return instance;
}

- (instancetype)init {
	if ((self = [super init]) != nil) {
		#if HIDREMOTE_THREADSAFETY_HARDENED_NOTIFICATION_HANDLING
        _runOnThread = NSThread.currentThread;
		#endif
	
		// Detect application becoming active/inactive
        let app = NSApplication.sharedApplication;
        let noteCenter = NSNotificationCenter.defaultCenter;
		[noteCenter addObserver:self selector:@selector(_appStatusChanged:) name:NSApplicationDidBecomeActiveNotification object:app];
		[noteCenter addObserver:self selector:@selector(_appStatusChanged:) name:NSApplicationWillResignActiveNotification object:app];
		[noteCenter addObserver:self selector:@selector(_appStatusChanged:) name:NSApplicationWillTerminateNotification	object:app];

		// Handle distributed notifications
        _pidString = @(getpid()).stringValue;

        let distNoteCenter = NSDistributedNotificationCenter.defaultCenter;
		[distNoteCenter addObserver:self selector:@selector(_handleNotifications:) name:kHIDRemoteDNHIDRemotePing object:nil];
		[distNoteCenter addObserver:self selector:@selector(_handleNotifications:) name:kHIDRemoteDNHIDRemoteRetry object:kHIDRemoteDNHIDRemoteRetryGlobalObject];
		[distNoteCenter addObserver:self selector:@selector(_handleNotifications:) name:kHIDRemoteDNHIDRemoteRetry object:_pidString];

		// Enabled by default: simulate hold events for plus/minus
		_simulateHoldEvents = YES;
		
		// Enabled by default: work around for a locking issue introduced with Security Update 2008-004 / 10.4.9 and beyond (credit for finding this workaround goes to Martin Kahr)
		_enableSecureEventInputWorkaround = YES;
		_secureInputNotification = 0;
		
		// Initialize instance variables
        _lastSeenRemoteID = -1;
		_lastSeenModel = kHIDRemoteModelUndetermined;
		_unusedButtonCodes = [[NSMutableArray alloc] init];
		_exclusiveLockLendingEnabled = NO;
		_sendExclusiveResourceReuseNotification = YES;
		_isApplicationTerminating = NO;
		
		// Send status notifications
		_sendStatusNotifications = YES;
	}

	return (self);
}

- (void)dealloc {
    let app = NSApplication.sharedApplication;
    let noteCenter = NSNotificationCenter.defaultCenter;
	[noteCenter removeObserver:self name:NSApplicationWillTerminateNotification object:app];
	[noteCenter removeObserver:self name:NSApplicationWillResignActiveNotification object:app];
	[noteCenter removeObserver:self name:NSApplicationDidBecomeActiveNotification object:app];

    let distNoteCenter = NSDistributedNotificationCenter.defaultCenter;
	[distNoteCenter removeObserver:self name:kHIDRemoteDNHIDRemotePing  object:nil];
	[distNoteCenter removeObserver:self name:kHIDRemoteDNHIDRemoteRetry object:kHIDRemoteDNHIDRemoteRetryGlobalObject];
	[distNoteCenter removeObserver:self name:kHIDRemoteDNHIDRemoteRetry object:_pidString];
	[distNoteCenter removeObserver:self name:nil object:nil]; /* As demanded by the documentation for -[NSDistributedNotificationCenter removeObserver:name:object:] */
	
	[self stopRemoteControl];
	[self setExclusiveLockLendingEnabled:NO];
	[self setDelegate:nil];
}

#pragma mark - PUBLIC: System Information
+ (BOOL)isCandelairInstalled {
    var masterPort = (mach_port_t)0;
    let result = IOMasterPort(MACH_PORT_NULL, &masterPort);
	if ((result != kIOReturnSuccess) || (masterPort == 0)) { return NO; }

    let matchingService = IOServiceGetMatchingService(masterPort, IOServiceMatching([kIOSPIRITIRController cStringUsingEncoding:NSUTF8StringEncoding]));
    let isInstalled = matchingService != 0;
    IOObjectRelease((io_object_t) matchingService);

    mach_port_deallocate(mach_task_self(), masterPort);
	return isInstalled;
}

+ (BOOL)isCandelairInstallationRequiredForRemoteMode:(HIDRemoteMode)remoteMode {
	// Determine OS version
	switch (self.OSXVersion) {
        // OS 10.6
		case 0x1060:
        // OS 10.6.1
        case 0x1061: {
            // OS X 10.6(.0) and OS X 10.6.1 require the Candelair driver for to be installed,
            // so that third party apps can acquire an exclusive lock on the receiver HID Device
            // via IOKit.
            switch (remoteMode) {
                case kHIDRemoteModeExclusive:
                case kHIDRemoteModeExclusiveAuto: {
                    if (![self isCandelairInstalled]) { return YES; }
                } break;

                default: {
                    return NO;
                }
            }
        } break;
	}
	
	return NO;
}

// Drop-in replacement for Gestalt(gestaltSystemVersion, &osXVersion) that avoids use of Gestalt for code targeting 10.10 or later
+ (SInt32)OSXVersion {
	static SInt32 sHRGestaltOSXVersion = 0;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        let osVersion = NSProcessInfo.processInfo.operatingSystemVersion;
        sHRGestaltOSXVersion = (SInt32)(0x01000 | ((osVersion.majorVersion - 10) << 8) | (osVersion.minorVersion << 4) | osVersion.patchVersion);
    });

	return sHRGestaltOSXVersion;
}

- (HIDRemoteAluminumRemoteSupportLevel)aluminiumRemoteSystemSupportLevel {
	var supportLevel = kHIDRemoteAluminumRemoteSupportLevelNone;

    for (HIDServiceAttributes *attr in _servicesMap.objectEnumerator) {
        let deviceSupportLevel = (NSNumber *)attr[kHIDRemoteAluminumRemoteSupportLevel];

        if ([deviceSupportLevel isKindOfClass:NSNumber.class] && deviceSupportLevel.intValue > (int)supportLevel) {
            supportLevel = deviceSupportLevel.unsignedIntValue;
        }
    }

	return supportLevel;
}

#pragma mark - PUBLIC: Interface / API
- (BOOL)startRemoteControl:(HIDRemoteMode)hidRemoteMode {
	if (!((_mode == kHIDRemoteModeNone) && (hidRemoteMode != kHIDRemoteModeNone))) {
        return NO;
    }

    do {
        // Get IOKit master port
        if ((IOMasterPort(bootstrap_port, &_masterPort) != kIOReturnSuccess) || (_masterPort == 0)) { break; }

        // Setup notification port
        _notifyPort = IONotificationPortCreate(_masterPort);

        if ((_notifyRLSource = IONotificationPortGetRunLoopSource(_notifyPort)) != NULL) {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), _notifyRLSource, kCFRunLoopCommonModes);
        } else { break; }

        // Setup SecureInput notification
        if ((hidRemoteMode == kHIDRemoteModeExclusive) || (hidRemoteMode == kHIDRemoteModeExclusiveAuto)) {
            let rootService = IORegistryEntryFromPath(_masterPort, kIOServicePlane ":/");
            if (rootService != 0) {
                if (IOServiceAddInterestNotification(_notifyPort, rootService, kIOBusyInterest, SecureInputNotificationCallback, (__bridge void *)self, &_secureInputNotification) != kIOReturnSuccess) {
                    break;
                }

                [self _updateSessionInformation];
            } else { break; }
        }

        // Setup notification matching dict
        let matchDict = IOServiceMatching(kIOHIDDeviceKey);
        CFRetain(matchDict);

        // Actually add notification
        if (IOServiceAddMatchingNotification(_notifyPort, kIOFirstMatchNotification, matchDict, ServiceMatchingCallback, (__bridge void *) self, &_matchingServicesIterator) != kIOReturnSuccess) {
            if (matchDict) { CFRelease(matchDict); }
            break;
        }

        // Setup serviceAttribMap
        _servicesMap = [[NSMutableDictionary alloc] init];
        if (_servicesMap == nil) {
            if (matchDict) { CFRelease(matchDict); }
            break;
        }

        // Phew .. everything went well!
        _mode = hidRemoteMode;
        CFRelease(matchDict);

        [self _serviceMatching:_matchingServicesIterator];
        [self _postStatusWithAction:kHIDRemoteDNStatusActionStart];

        // Register for system wake notifications
        [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self selector:@selector(_computerDidWake:) name:NSWorkspaceDidWakeNotification object:nil];

        return YES;

    } while (0);


    [self stopRemoteControl];
	return NO;
}

- (void)stopRemoteControl {
	var serviceCount = 0;

	_autoRecover = NO;
	_isStopping = YES;

	if (_autoRecoveryTimer != nil) {
		[_autoRecoveryTimer invalidate];
        _autoRecoveryTimer = nil;
	}

	if (_servicesMap != nil) {
		let cloneDict = (HIDServicesMap *)_servicesMap.copy;
        for (NSNumber *item in cloneDict) {
            [self _destructService:(io_object_t)item.unsignedIntValue];
            serviceCount++;
        }
        _servicesMap = nil;
	}

	if (_matchingServicesIterator != 0) {
		IOObjectRelease((io_object_t) _matchingServicesIterator);
		_matchingServicesIterator = 0;
	}
	
	if (_secureInputNotification != 0) {
		IOObjectRelease((io_object_t) _secureInputNotification);
		_secureInputNotification = 0;
	}

	if (_notifyRLSource != NULL) {
		CFRunLoopSourceInvalidate(_notifyRLSource);
		_notifyRLSource = NULL;
	}

	if (_notifyPort != NULL) {
		IONotificationPortDestroy(_notifyPort);
		_notifyPort = NULL;
	}

	if (_masterPort != 0) {
		mach_port_deallocate(mach_task_self(), _masterPort);
		_masterPort = 0;
	}

	if (_returnToPID != nil) {
        _returnToPID = nil;
	}

	if (_mode != kHIDRemoteModeNone) {
		// Post status
		[self _postStatusWithAction:kHIDRemoteDNStatusActionStop];

		if (_sendStatusNotifications) {
			// In case we were not ready to lend it earlier, tell other HIDRemote apps that the resources (if any were used) are now again available for use by other applications
			if (((_mode == kHIDRemoteModeExclusive) ||(_mode == kHIDRemoteModeExclusiveAuto)) &&
                (_sendExclusiveResourceReuseNotification == YES) && (_exclusiveLockLendingEnabled == NO) && (serviceCount > 0)) {
				_mode = kHIDRemoteModeNone;
				
				if (!_isRestarting) {
                    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kHIDRemoteDNHIDRemoteRetry
                                                                                   object:kHIDRemoteDNHIDRemoteRetryGlobalObject
                                                                                 userInfo:self.pidAndBundle
                                                                       deliverImmediately:YES];
                }
			}
		}

		// Unregister from system wake notifications
		[[NSWorkspace sharedWorkspace].notificationCenter removeObserver:self name:NSWorkspaceDidWakeNotification object:nil];
	}
	
	_mode = kHIDRemoteModeNone;
	_isStopping = NO;
}

- (SInt32)lastSeenRemoteControlID {
    return _lastSeenRemoteID;
}

- (BOOL)isStarted {
	return _mode != kHIDRemoteModeNone;
}

- (NSUInteger)activeRemoteControlCount {
    return _servicesMap ? _servicesMap.count : 0;
}

- (void)setUnusedButtonCodes:(HIDRemoteButtonCodesList *)codes {
	_unusedButtonCodes = codes;
	[self _postStatusWithAction:kHIDRemoteDNStatusActionUpdate];
}

#pragma mark - PUBLIC: Expert APIs

- (void)setExclusiveLockLendingEnabled:(BOOL)newExclusiveLockLendingEnabled {
	if (newExclusiveLockLendingEnabled != _exclusiveLockLendingEnabled) {
		_exclusiveLockLendingEnabled = newExclusiveLockLendingEnabled;
		
		if (_exclusiveLockLendingEnabled) {
			[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleNotifications:) name:kHIDRemoteDNHIDRemoteStatus object:nil];
		} else {
			[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:kHIDRemoteDNHIDRemoteStatus object:nil];
            _waitForReturnByPID = nil;
		}
	}
}

#pragma mark - PRIVATE: Application becomes active / inactive handling for kHIDRemoteModeExclusiveAuto
- (void)_appStatusChanged:(NSNotification *)notification {
	#if HIDREMOTE_THREADSAFETY_HARDENED_NOTIFICATION_HANDLING
    // OS X 10.5+ only
	if ([self respondsToSelector:@selector(performSelector:onThread:withObject:waitUntilDone:)]) {
		if (NSThread.currentThread != _runOnThread) {
			if ([notification.name isEqual:NSApplicationDidBecomeActiveNotification]) {
				if (!_autoRecover) {
					return;
				}
			}
			
			if ([notification.name isEqual:NSApplicationWillResignActiveNotification]) {
				if (_mode != kHIDRemoteModeExclusiveAuto) {
					return;
				}
			}
		
			[self performSelector:@selector(_appStatusChanged:)
                         onThread:_runOnThread
                       withObject:notification
                    waitUntilDone:[notification.name isEqual:NSApplicationWillTerminateNotification]];
			return;
		}
	}
	#endif

	if (notification != nil) {
		if (_autoRecoveryTimer != nil) {
			[_autoRecoveryTimer invalidate];
            _autoRecoveryTimer = nil;
		}

		if ([notification.name isEqual:NSApplicationDidBecomeActiveNotification]) {
			if (_autoRecover) {
				// Delay autorecover by 0.1 to avoid race conditions
				if ((_autoRecoveryTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.1] interval:0.1 target:self selector:@selector(_delayedAutoRecovery:) userInfo:nil repeats:NO]) != nil) {
                    [[NSRunLoop currentRunLoop] addTimer:_autoRecoveryTimer forMode:NSRunLoopCommonModes];
				}
			}
		}

		if ([notification.name isEqual:NSApplicationWillResignActiveNotification]) {
			if (_mode == kHIDRemoteModeExclusiveAuto) {
				[self stopRemoteControl];
				_autoRecover = YES;
			}
		}
		
		if ([notification.name isEqual:NSApplicationWillTerminateNotification]) {
			_isApplicationTerminating = YES;
			if ([self isStarted]) {
				[self stopRemoteControl];
			}
		}
	}
}

- (void)_delayedAutoRecovery:(NSTimer *)aTimer {
	[_autoRecoveryTimer invalidate];
    _autoRecoveryTimer = nil;

	if (_autoRecover) {
		[self startRemoteControl:kHIDRemoteModeExclusiveAuto];
		_autoRecover = NO;
	}
}


#pragma mark - PRIVATE: Distributed notifiations handling
- (void)_postStatusWithAction:(NSString *)action {
    if (_sendStatusNotifications) {
        let userInfo = (NSMutableDictionary<NSString *, id> *)[@{
            kHIDRemoteDNStatusHIDRemoteVersionKey: @1,
            kHIDRemoteDNStatusPIDKey: @(getpid()),
            kHIDRemoteDNStatusModeKey: @(_mode),
            kHIDRemoteDNStatusRemoteControlCountKey: @(self.activeRemoteControlCount),
            kHIDRemoteDNStatusUnusedButtonCodesKey: (_unusedButtonCodes ?: @[]),
            kHIDRemoteDNStatusActionKey: action,
            (__bridge NSString *)kCFBundleIdentifierKey: (NSBundle.mainBundle.bundleIdentifier ?: @""),
        } mutableCopy];

        if (_returnToPID != nil) {
            userInfo[kHIDRemoteDNStatusReturnToPIDKey] = _returnToPID;
        }

        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kHIDRemoteDNHIDRemoteStatus
                                                                       object:_pidString ?: @(getpid()).stringValue
                                                                     userInfo:userInfo
                                                           deliverImmediately:YES];
    }
}

- (void)_handleNotifications:(NSNotification *)notification {
	#if HIDREMOTE_THREADSAFETY_HARDENED_NOTIFICATION_HANDLING
    // OS X 10.5+ only
	if ([self respondsToSelector:@selector(performSelector:onThread:withObject:waitUntilDone:)]) {
		if (NSThread.currentThread != _runOnThread) {
			[self performSelector:@selector(_handleNotifications:) onThread:_runOnThread withObject:notification waitUntilDone:NO];
			return;
		}
	}
	#endif

    let notificationName = notification.name;
    if (notificationName == nil) {
        return;
    }

    if ([notificationName isEqual:kHIDRemoteDNHIDRemotePing]) {
        [self _postStatusWithAction:kHIDRemoteDNStatusActionUpdate];
    }

    if ([notificationName isEqual:kHIDRemoteDNHIDRemoteRetry] && self.isStarted) {
        var retry = YES;

        // Ignore our own global retry broadcasts
        if ([notification.object isEqual:kHIDRemoteDNHIDRemoteRetryGlobalObject]) {
            let fromPID = (NSNumber *)notification.userInfo[kHIDRemoteDNStatusPIDKey];
            if (fromPID != nil && getpid() == (pid_t)fromPID.integerValue) {
                retry = NO;
            }
        }

        if (retry) {
            if ([self.delegate respondsToSelector:@selector(hidRemote:shouldRetryExclusiveLockWithInfo:)]) {
                retry = [self.delegate hidRemote:self shouldRetryExclusiveLockWithInfo:notification.userInfo ?: @{}];
            }
        }

        if (retry) {
            let mode = _mode;
            if (mode != kHIDRemoteModeNone) {
                _isRestarting = YES;
                [self stopRemoteControl];
                _returnToPID = nil;
                [self startRemoteControl:mode];
                _isRestarting = NO;

                if (mode != kHIDRemoteModeShared) {
                    _returnToPID = (NSNumber *)notification.userInfo[kHIDRemoteDNStatusPIDKey];
                }
            }
        } else {
            let cacheReturnPID = _returnToPID;
            _returnToPID = notification.userInfo[kHIDRemoteDNStatusPIDKey];
            [self _postStatusWithAction:kHIDRemoteDNStatusActionNoNeed];
            _returnToPID = cacheReturnPID;
        }
    }

    if (_exclusiveLockLendingEnabled && [notificationName isEqual:kHIDRemoteDNHIDRemoteStatus]) {
        var action = (NSString *)notification.userInfo[kHIDRemoteDNStatusActionKey];
        if (action) {
            if ((_mode == kHIDRemoteModeNone) && (_waitForReturnByPID != nil)) {
                let pidNumber = (NSNumber *)notification.userInfo[kHIDRemoteDNStatusPIDKey];
                if (pidNumber != nil) {
                    var returnToPIDNumber = (NSNumber *)notification.userInfo[kHIDRemoteDNStatusReturnToPIDKey];

                    if ([action isEqual:kHIDRemoteDNStatusActionStart] && [pidNumber isEqual:_waitForReturnByPID]) {
                        let startMode = (NSNumber *)notification.userInfo[kHIDRemoteDNStatusModeKey];
                        if (startMode.unsignedIntValue == kHIDRemoteModeShared) {
                            returnToPIDNumber = @(getpid());
                            action = kHIDRemoteDNStatusActionNoNeed;
                        }
                    }

                    if (returnToPIDNumber != nil && ([action isEqual:kHIDRemoteDNStatusActionStop] || [action isEqual:kHIDRemoteDNStatusActionNoNeed])) {
                        if ([pidNumber isEqual:_waitForReturnByPID] && (returnToPIDNumber.integerValue == getpid())) {
                            _waitForReturnByPID = nil;

                            if ([self.delegate respondsToSelector:@selector(hidRemote:exclusiveLockReleasedByApplicationWithInfo:)]) {
                                [self.delegate hidRemote:self exclusiveLockReleasedByApplicationWithInfo:notification.userInfo ?: @{}];
                            } else {
                                [self startRemoteControl:kHIDRemoteModeExclusive];
                            }
                        }
                    }
                }
            }

            if (_mode == kHIDRemoteModeExclusive && [action isEqual:kHIDRemoteDNStatusActionStart]) {
                let originPID = (NSNumber *)notification.userInfo[kHIDRemoteDNStatusPIDKey];
                if (originPID.integerValue != getpid()) {
                    var lendLock = YES;

                    if ([self.delegate respondsToSelector:@selector(hidRemote:lendExclusiveLockToApplicationWithInfo:)]) {
                        lendLock = [self.delegate hidRemote:self lendExclusiveLockToApplicationWithInfo:notification.userInfo ?: @{}];
                    }

                    if (lendLock) {
                        _waitForReturnByPID = originPID;
                        if (_waitForReturnByPID != nil) {
                            [self stopRemoteControl];
                            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:kHIDRemoteDNHIDRemoteRetry
                                                                                           object:_waitForReturnByPID.stringValue
                                                                                         userInfo:self.pidAndBundle
                                                                               deliverImmediately:YES];
                        }
                    }
                }
            }
        }
    }

}

- (NSDictionary<NSString *, id> *)pidAndBundle {
    return @{
        kHIDRemoteDNStatusPIDKey: @(getpid()),
        (__bridge NSString *)kCFBundleIdentifierKey: (NSBundle.mainBundle.bundleIdentifier ?: @"")
    };
}

#pragma mark - PRIVATE: Service setup and destruction
- (BOOL)_prematchService:(io_registry_entry_t)service {
	var serviceMatches = NO;

	if (service != 0) {
        let ioClass = (__bridge_transfer NSString *)IORegistryEntryCreateCFProperty(service, CFSTR(kIOClassKey), kCFAllocatorDefault, 0);
		if ([ioClass isKindOfClass:NSString.class]) {
			// Match on Apple's AppleIRController and old versions of the Remote Buddy IR Controller
			if ([ioClass isEqual:kAppleIRController] || [ioClass isEqual:kRBIOKitAIREmu]) {
                let compatibilityDevice = (__bridge_transfer NSNumber *)IORegistryEntryCreateCFProperty(service, kCandelairHIDRemoteCompatibilityDevice, kCFAllocatorDefault, 0);
				serviceMatches = ![compatibilityDevice isEqualToNumber:@YES];
			}

			// Match on the virtual IOSPIRIT IR Controller
			if ([ioClass isEqual:kIOSPIRITIRController]) {
				serviceMatches = YES;
			}
		}

		// Match on services that claim compatibility with the HID Remote class (Candelair or third-party) by having a property of CandelairHIDRemoteCompatibilityMask = 1 <Type: Number>
        let compatibilityMask = (__bridge_transfer NSNumber *)IORegistryEntryCreateCFProperty(service, kCandelairHIDRemoteCompatibilityMask, kCFAllocatorDefault, 0);
        if ([compatibilityMask isKindOfClass:NSNumber.class]) {
            serviceMatches = (compatibilityMask.unsignedIntValue & kHIDRemoteCompatibilityFlagsStandardHIDRemoteDevice);
        }
	}

	if ([self.delegate respondsToSelector:@selector(hidRemote:inspectNewHardwareWithService:prematchResult:)]) {
		serviceMatches = [(id<HIDRemoteDelegate>)self.delegate hidRemote:self inspectNewHardwareWithService:service prematchResult:serviceMatches];
	}
	
	return serviceMatches;
}

- (HIDRemoteButtonCode)buttonCodeForUsage:(NSUInteger)usage usagePage:(NSUInteger)usagePage {
	switch (usagePage) {
        case kHIDPage_Consumer: {
            switch (usage) {
                case kHIDUsage_Csmr_MenuPick:
                    // Aluminum Remote: Center
                    return (kHIDRemoteButtonCodeCenter|kHIDRemoteButtonCodeAluminumMask);

                case kHIDUsage_Csmr_ModeStep:
                    // Aluminium Remote: Center Hold
                    return (kHIDRemoteButtonCodeCenterHold|kHIDRemoteButtonCodeAluminumMask);

                case kHIDUsage_Csmr_PlayOrPause:
                    // Aluminum Remote: Play/Pause
                    return(kHIDRemoteButtonCodePlay|kHIDRemoteButtonCodeAluminumMask);
                case kHIDUsage_Csmr_Rewind:
                    return kHIDRemoteButtonCodeLeftHold;
                case kHIDUsage_Csmr_FastForward:
                    return kHIDRemoteButtonCodeRightHold;
                case kHIDUsage_Csmr_Menu:
                    return kHIDRemoteButtonCodeMenuHold;
                case kHIDUsage_Csmr_VolumeIncrement:
                    return kHIDRemoteButtonCodeUp;
                case kHIDUsage_Csmr_VolumeDecrement:
                    return kHIDRemoteButtonCodeDown;
            }
        } break;
		
        case kHIDPage_GenericDesktop: {
            switch (usage) {
                case kHIDUsage_GD_SystemAppMenu:
                    return kHIDRemoteButtonCodeMenu;
                case kHIDUsage_GD_SystemMenu:
                    return kHIDRemoteButtonCodeCenter;
                case kHIDUsage_GD_SystemMenuRight:
                    return kHIDRemoteButtonCodeRight;
                case kHIDUsage_GD_SystemMenuLeft:
                    return kHIDRemoteButtonCodeLeft;
                case kHIDUsage_GD_SystemMenuUp: {
                    // macOS 10.13.6 posts kHIDUsage_GD_SystemMenuUp alongside kHIDUsage_Csmr_VolumeIncrement,
                    // which ends up being interpreted as a double press. To avoid this, this usage is ignored
                    // when running under 10.13.6 and later.
                    if ([HIDRemote OSXVersion] < 0x10d6) {
                        return kHIDRemoteButtonCodeUp;
                    }
                } break;

                case kHIDUsage_GD_SystemMenuDown: {
                    // macOS 10.13.6 posts kHIDUsage_GD_SystemMenuDown alongside kHIDUsage_Csmr_VolumeDecrement,
                    // which ends up being interpreted as a double press. To avoid this, this usage is ignored
                    // when running under 10.13.6 and later.
                    if ([HIDRemote OSXVersion] < 0x10d6) {
                        return kHIDRemoteButtonCodeDown;
                    }
                } break;
            }
        } break;
		
        case 0x06: { /* Reserved */
            switch (usage) {
                case 0x22:
                    return kHIDRemoteButtonCodeIDChanged;
            }
        } break;
		
        case 0xFF01: { /* Vendor specific */
            switch (usage) {
                case 0x23:
                    return kHIDRemoteButtonCodeCenterHold;

                #ifdef _HIDREMOTE_EXTENSIONS
                #define _HIDREMOTE_EXTENSIONS_SECTION 2
                #include "HIDRemoteAdditions.h"
                #undef _HIDREMOTE_EXTENSIONS_SECTION
                #endif /* _HIDREMOTE_EXTENSIONS */
            }
        } break;
	}
	
	return kHIDRemoteButtonCodeNone;
}

- (BOOL)_setupService:(io_service_t)service {
	IOHIDDeviceInterface122 **device = NULL;
	IOCFPlugInInterface **plugin = NULL;
	IOHIDQueueInterface **queue	= NULL;
	io_object_t notification = 0;
	CFRunLoopSourceRef queueEventSource	= NULL;
    NSMutableDictionary<NSString *, id> *hidAttributes = nil;
	CFArrayRef hidElements = NULL;

	if (![self _prematchService:service]) {
		return NO;
	}

    var error = (NSError *)nil;
    var errorCode = (NSUInteger)0;
    BOOL opened = NO, queueStarted = NO;

	do {
        // Create a plugin interface ..
        SInt32 score = 0;
        let kernResult = IOCreatePlugInInterfaceForService(service, kIOHIDDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &plugin, &score);
        if (kernResult != kIOReturnSuccess) {
            error = [NSError errorWithDomain:NSMachErrorDomain code:kernResult userInfo:nil];
            errorCode = 1;
            break;
        }

        // .. use it to get the HID interface ..
        var hResult = (HRESULT)((*plugin)->QueryInterface(plugin, CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID122), (LPVOID)&device));

        if ((hResult != S_OK) || (device == NULL)) {
            error = [NSError errorWithDomain:NSMachErrorDomain code:hResult userInfo:nil];
            errorCode = 2;
            break;
        }

        // .. then open it ..
        switch (_mode) {
            case kHIDRemoteModeShared: {
                hResult = (*device)->open(device, kIOHIDOptionsTypeNone);
            } break;

            case kHIDRemoteModeExclusive:
            case kHIDRemoteModeExclusiveAuto: {
                hResult = (*device)->open(device, kIOHIDOptionsTypeSeizeDevice);
            } break;

            default: {
                goto cleanUp; // Ugh! But there are no "double breaks" available in C AFAIK ..
            }
        }

        if (hResult != S_OK) {
            error = [NSError errorWithDomain:NSMachErrorDomain code:hResult userInfo:nil];
            errorCode = 3;
            break;
        }

        opened = YES;

        // .. query the HID elements ..
        {
            let returnCode = (*device)->copyMatchingElements(device, NULL, &hidElements);
            if ((returnCode != kIOReturnSuccess) || (hidElements == NULL)) {
                error = [NSError errorWithDomain:NSMachErrorDomain code:returnCode userInfo:nil];
                errorCode = 4;
                break;
            }
        }

        // Setup an event queue for HID events!
        queue = (*device)->allocQueue(device);
        if (queue == NULL) {
            error = [NSError errorWithDomain:NSMachErrorDomain code:kIOReturnError userInfo:nil];
            errorCode = 5;
            break;
        }

        {
            let returnCode = (*queue)->create(queue, 0, 32);
            if (returnCode != kIOReturnSuccess) {
                error = [NSError errorWithDomain:NSMachErrorDomain code:returnCode userInfo:nil];
                errorCode = 6;
                break;
            }
        }


		// Setup of attributes stored for this HID device
        hidAttributes = [NSMutableDictionary dictionaryWithDictionary:@{
            kHIDRemoteCFPluginInterface: [NSValue valueWithPointer:(const void *)plugin],
            kHIDRemoteHIDDeviceInterface: [NSValue valueWithPointer:(const void *)device],
            kHIDRemoteHIDQueueInterface: [NSValue valueWithPointer:(const void *)queue],
        }];

		{
			UInt32 i, hidElementCnt = (UInt32)CFArrayGetCount(hidElements);
			var cookieButtonCodeLUT = [[NSMutableDictionary alloc] init];
			var cookieCount	= [[NSMutableDictionary alloc] init];

			if ((cookieButtonCodeLUT == nil) || (cookieCount == nil)) {
                cookieButtonCodeLUT = nil;
                cookieCount = nil;
				error = [NSError errorWithDomain:NSMachErrorDomain code:kIOReturnError userInfo:nil];
				errorCode = 7;
				break;
			}

			// Analyze the HID elements and find matching elements
			for (i = 0; i < hidElementCnt; i++) {
				let hidDict = CFArrayGetValueAtIndex(hidElements, i);
				let usage = (NSNumber *)CFDictionaryGetValue(hidDict, CFSTR(kIOHIDElementUsageKey));
				let usagePage = (NSNumber *)CFDictionaryGetValue(hidDict, CFSTR(kIOHIDElementUsagePageKey));
				let cookie = (NSNumber *)CFDictionaryGetValue(hidDict, CFSTR(kIOHIDElementCookieKey));

				if ((usage != nil) && (usagePage != nil) && (cookie != nil)) {
					// Find the button codes for the ID combos
					let buttonCode = [self buttonCodeForUsage:usage.unsignedIntValue usagePage:usagePage.unsignedIntValue];

					#ifdef _HIDREMOTE_EXTENSIONS
						// Debug logging code
						#define _HIDREMOTE_EXTENSIONS_SECTION 3
						#include "HIDRemoteAdditions.h"
						#undef _HIDREMOTE_EXTENSIONS_SECTION
					#endif /* _HIDREMOTE_EXTENSIONS */

					// Did record match?
					if (buttonCode != kHIDRemoteButtonCodeNone) {
						let pairString = [[NSString alloc] initWithFormat:@"%u_%u", usagePage.unsignedIntValue, usage.unsignedIntValue];
                        let buttonCodeValue  = @(buttonCode);

						#ifdef _HIDREMOTE_EXTENSIONS
							// Debug logging code
							#define _HIDREMOTE_EXTENSIONS_SECTION 4
							#include "HIDRemoteAdditions.h"
							#undef _HIDREMOTE_EXTENSIONS_SECTION
						#endif /* _HIDREMOTE_EXTENSIONS */

						cookieCount[pairString] = buttonCodeValue;
						cookieButtonCodeLUT[cookie] = buttonCodeValue;

						(*queue)->addElement(queue, (IOHIDElementCookie) cookie.unsignedIntValue, 0);

						#ifdef _HIDREMOTE_EXTENSIONS
							// Get current Apple Remote ID value
							#define _HIDREMOTE_EXTENSIONS_SECTION 7
							#include "HIDRemoteAdditions.h"
							#undef _HIDREMOTE_EXTENSIONS_SECTION
						#endif /* _HIDREMOTE_EXTENSIONS */
					}
				}
			}

			// Compare number of *unique* matches (thus the cookieCount dictionary) with required minimum
			if (cookieCount.count < 10) {
                cookieButtonCodeLUT = nil;
                cookieCount = nil;

				error = [NSError errorWithDomain:NSMachErrorDomain code:kIOReturnError userInfo:nil];
				errorCode = 8;
				break;
			}

			hidAttributes[kHIDRemoteCookieButtonCodeLUT] = cookieButtonCodeLUT;

            cookieButtonCodeLUT = nil;
            cookieCount = nil;
		}

        {
            // Finish setup of IOHIDQueueInterface with CFRunLoop
            let returnCode = (*queue)->createAsyncEventSource(queue, &queueEventSource);
            if ((returnCode != kIOReturnSuccess) || (queueEventSource == NULL)) {
                error = [NSError errorWithDomain:NSMachErrorDomain code:returnCode userInfo:nil];
                errorCode = 9;
                break;
            }
        }

        {
            let returnCode = (*queue)->setEventCallout(queue, HIDEventCallback, (void *)((intptr_t)service), (__bridge void *)self);
            if (returnCode != kIOReturnSuccess) {
                error = [NSError errorWithDomain:NSMachErrorDomain code:returnCode userInfo:nil];
                errorCode = 10;
                break;
            }
        }

		CFRunLoopAddSource(	CFRunLoopGetCurrent(), queueEventSource, kCFRunLoopCommonModes);
		hidAttributes[kHIDRemoteCFRunLoopSource] = [NSValue valueWithPointer:(const void *)queueEventSource];

        {
            let returnCode = (*queue)->start(queue);
            if (returnCode != kIOReturnSuccess) {
                error = [NSError errorWithDomain:NSMachErrorDomain code:returnCode userInfo:nil];
                errorCode = 11;
                break;
            }
        }

		queueStarted = YES;

		// Setup device notifications
        {
            let returnCode = IOServiceAddInterestNotification(_notifyPort, service, kIOGeneralInterest, ServiceNotificationCallback, (__bridge void *)(self), &notification);
            if ((returnCode != kIOReturnSuccess) || (notification==0)) {
                error = [NSError errorWithDomain:NSMachErrorDomain code:returnCode userInfo:nil];
                errorCode = 12;
                break;
            }
        }

		hidAttributes[kHIDRemoteServiceNotification] = @(notification);

		// Retain service
		if (IOObjectRetain(service) != kIOReturnSuccess) {
			error = [NSError errorWithDomain:NSMachErrorDomain code:kIOReturnError userInfo:nil];
			errorCode = 13;
			break;
		}

		hidAttributes[kHIDRemoteService] = @(service);

		// Get some (somewhat optional) infos on the device
		{
			NSString *product, *manufacturer, *transport;

            if ((product = (NSString *)CFBridgingRelease(IORegistryEntryCreateCFProperty((io_registry_entry_t)service, (__bridge CFStringRef)kHIDRemoteProduct, kCFAllocatorDefault, 0))) != NULL) {
				if ([product isKindOfClass:NSString.class]) {
					hidAttributes[kHIDRemoteProduct] = product;
				}
			}

            if ((manufacturer = CFBridgingRelease(IORegistryEntryCreateCFProperty((io_registry_entry_t)service, (__bridge CFStringRef)kHIDRemoteManufacturer, kCFAllocatorDefault, 0))) != NULL) {
				if ([manufacturer isKindOfClass:NSString.class]) {
					hidAttributes[kHIDRemoteManufacturer] = manufacturer;
				}
			}

            if ((transport = CFBridgingRelease(IORegistryEntryCreateCFProperty((io_registry_entry_t)service, (__bridge CFStringRef)kHIDRemoteTransport, kCFAllocatorDefault, 0))) != NULL) {
				if ([transport isKindOfClass:NSString.class]) {
					hidAttributes[kHIDRemoteTransport] = transport;
				}
			}
		}

		// Determine Aluminum Remote support
		{
			var supportLevel = (HIDRemoteAluminumRemoteSupportLevel)kHIDRemoteAluminumRemoteSupportLevelNone;

			if ((_mode == kHIDRemoteModeExclusive) || (_mode == kHIDRemoteModeExclusiveAuto)) {
                let aluSupport = (NSNumber *)CFBridgingRelease(IORegistryEntryCreateCFProperty((io_registry_entry_t)service, (__bridge CFStringRef)kHIDRemoteAluminumRemoteSupportOnDemand, kCFAllocatorDefault, 0));
				// Determine if this driver offers on-demand support for the Aluminum Remote (only relevant under OS versions < 10.6.2)
				if (aluSupport != nil) {
					// There is => request the driver to enable it for us
					if (IORegistryEntrySetCFProperty((io_registry_entry_t)service, kEnableAluminumRemoteSupportForMe, (__bridge CFTypeRef)(@{@"pid": @(getpid()), @"uid": @(getuid()) })) == kIOReturnSuccess) {
						if ([aluSupport isKindOfClass:NSNumber.class]) {
							supportLevel = (HIDRemoteAluminumRemoteSupportLevel)aluSupport.unsignedIntValue;
						}

						hidAttributes[kHIDRemoteAluminumRemoteSupportOnDemand] = @YES;
					}
				}
			}

			if (supportLevel == kHIDRemoteAluminumRemoteSupportLevelNone) {
                let aluSupport = (NSNumber *)CFBridgingRelease(IORegistryEntryCreateCFProperty((io_registry_entry_t)service, (__bridge CFStringRef)kHIDRemoteAluminumRemoteSupportLevel, kCFAllocatorDefault, 0));
                if (aluSupport != nil) {
                    if ([aluSupport isKindOfClass:NSNumber.class]) {
                        supportLevel = (HIDRemoteAluminumRemoteSupportLevel)aluSupport.unsignedIntValue;
                    }
				} else {
                    let ioKitClassName = (NSString *)CFBridgingRelease(IORegistryEntryCreateCFProperty((io_registry_entry_t)service, CFSTR(kIOClassKey), kCFAllocatorDefault, 0));
					if (ioKitClassName && [ioKitClassName isEqualToString:kAppleIRController] && [HIDRemote OSXVersion] >= 0x1062) {
                        // Support for the Aluminum Remote was added only with OS 10.6.2. Previous versions can not distinguish
                        // between the Center and the new, seperate Play/Pause button. They'll recognize both as presses of the
                        // "Center" button.
                        //
                        // You CAN, however, receive Aluminum Remote button presses even under OS 10.5 when using Remote Buddy's
                        // Virtual Remote. While Remote Buddy does support the Aluminum Remote across all OS releases it runs on,
                        // its Virtual Remote can only emulate Aluminum Remote button presses under OS 10.5 and up in order not to
                        // break compatibility with applications whose IR Remote code relies on driver internals. [13-Nov-09]
                        supportLevel = kHIDRemoteAluminumRemoteSupportLevelNative;
					}
				}
			}

			hidAttributes[kHIDRemoteAluminumRemoteSupportLevel] = @(supportLevel);
		}

		// Add it to the serviceAttribMap
		_servicesMap[@(service)] = hidAttributes;

		// And we're done with setup ..
		if ([self.delegate respondsToSelector:@selector(hidRemote:foundNewHardwareWithAttributes:)]) {
			[(NSObject <HIDRemoteDelegate> *)self.delegate hidRemote:self foundNewHardwareWithAttributes:hidAttributes];
		}
        hidAttributes = nil;
		return YES;
	} while(0);


cleanUp:
	if ([self.delegate respondsToSelector:@selector(hidRemote:failedNewHardwareWithError:)]) {
		if (error != nil) {
			error = [NSError errorWithDomain:error.domain code:error.code userInfo:@{ @"InternalErrorCode": @(errorCode) }];
		}
		[(NSObject <HIDRemoteDelegate> *)self.delegate hidRemote:self failedNewHardwareWithError:error];
	}
	
	// An error occured or this device is not of interest .. cleanup ..
	if (notification != 0) {
		IOObjectRelease(notification);
		notification = 0;
	}

	if (queueEventSource != NULL) {
		CFRunLoopSourceInvalidate(queueEventSource);
		queueEventSource=NULL;
	}
	
	if (queue != NULL) {
		if (queueStarted) {
			(*queue)->stop(queue);
		}
		(*queue)->dispose(queue);
		(*queue)->Release(queue);
		queue = NULL;
	}

	if (hidAttributes != nil) {
        hidAttributes = nil;
	}
	
	if (hidElements != NULL) {
		CFRelease(hidElements);
		hidElements = NULL;
	}
	
	if (device != NULL) {
		if (opened) {
			(*device)->close(device);
		}
		(*device)->Release(device);
		// opened = NO;
		device = NULL;
	}
	
	if (plugin != NULL) {
		IODestroyPlugInInterface(plugin);
		plugin = NULL;
	}
	
	return (NO);
}

- (void)_destructService:(io_service_t)service {
	if (service == 0) { return; }

    let serviceDict = _servicesMap[@(service)];
    if (!serviceDict) { return; }

    let serviceNotification = (io_object_t)[serviceDict[kHIDRemoteServiceNotification] unsignedIntValue];
    let remoteService = (io_object_t)[serviceDict[kHIDRemoteService] unsignedIntValue];
    let queueEventSource = (CFRunLoopSourceRef)[serviceDict[kHIDRemoteCFRunLoopSource] pointerValue];
    let hidQueueInterface = (IOHIDQueueInterface **)[serviceDict[kHIDRemoteHIDQueueInterface] pointerValue];
    let hidDeviceInterface = (IOHIDDeviceInterface122 **)[serviceDict[kHIDRemoteHIDDeviceInterface] pointerValue];
    let pluginInterface = (IOCFPlugInInterface **)[serviceDict[kHIDRemoteCFPluginInterface] pointerValue];
    let buttonCookies = (NSDictionary *)serviceDict[kHIDRemoteCookieButtonCodeLUT];
    let holdTimer = (NSTimer *)serviceDict[kHIDRemoteSimulateHoldEventsTimer];

    [_servicesMap removeObjectForKey:@(service)];

    if (serviceDict[kHIDRemoteAluminumRemoteSupportOnDemand] && [serviceDict[kHIDRemoteAluminumRemoteSupportOnDemand] boolValue] && (remoteService != 0)) {
        // We previously requested the driver to enable Aluminum Remote support for us. Tell it to turn it off again - now that we no longer need it
        IORegistryEntrySetCFProperty((io_registry_entry_t)remoteService, kEnableAluminumRemoteSupportForMe, (__bridge CFTypeRef)@{ @"pid": @(getpid()), @"uid": @(getuid()) });
    }

    if ([self.delegate respondsToSelector:@selector(hidRemote:releasedHardwareWithAttributes:)]) {
        [(NSObject <HIDRemoteDelegate> *)self.delegate hidRemote:self releasedHardwareWithAttributes:serviceDict];
    }

    if (holdTimer != nil) {
        [holdTimer invalidate];
    }

    if (serviceNotification != 0) {
        IOObjectRelease(serviceNotification);
    }

    if (queueEventSource != NULL) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), queueEventSource, kCFRunLoopCommonModes);
    }

    if ((hidQueueInterface != NULL) && (buttonCookies != nil)) {
        for (NSNumber *cookie in buttonCookies) {
            if ((*hidQueueInterface)->hasElement(hidQueueInterface, (IOHIDElementCookie)cookie.unsignedIntValue)) {
                (*hidQueueInterface)->removeElement(hidQueueInterface, (IOHIDElementCookie)cookie.unsignedIntValue);
            }
        }
    }

    if (hidQueueInterface != NULL) {
        (*hidQueueInterface)->stop(hidQueueInterface);
        (*hidQueueInterface)->dispose(hidQueueInterface);
        (*hidQueueInterface)->Release(hidQueueInterface);
    }

    if (hidDeviceInterface != NULL) {
        (*hidDeviceInterface)->close(hidDeviceInterface);
        (*hidDeviceInterface)->Release(hidDeviceInterface);
    }

    if (pluginInterface != NULL) {
        IODestroyPlugInInterface(pluginInterface);
    }

    if (remoteService != 0) {
        IOObjectRelease(remoteService);
    }
}


#pragma mark - PRIVATE: HID Event handling
- (void)_simulateHoldEvent:(NSTimer *)timer {
    let attributes = (MutableHIDServiceAttributes *)timer.userInfo;
	if ([attributes isKindOfClass:NSMutableDictionary.class]) {
        let holdTimer = (NSTimer *)attributes[kHIDRemoteSimulateHoldEventsTimer];
        let buttonCode = (NSNumber *)attributes[kHIDRemoteSimulateHoldEventsOriginButtonCode];
		if (holdTimer && buttonCode) {
			[holdTimer invalidate];
			[attributes removeObjectForKey:kHIDRemoteSimulateHoldEventsTimer];
			[self _sendButtonCode:(((HIDRemoteButtonCode)buttonCode.unsignedIntValue) | kHIDRemoteButtonCodeHoldMask)
                        isPressed:YES
                   attributes:attributes];
		}
	}
}

- (void)_handleButtonCode:(HIDRemoteButtonCode)buttonCode isPressed:(BOOL)isPressed attributes:(MutableHIDServiceAttributes *)attributes {
	switch (buttonCode) {
        case kHIDRemoteButtonCodeIDChanged: {
            // Do nothing, this is handled seperately
        } break;

		case kHIDRemoteButtonCodeUp:
        case kHIDRemoteButtonCodeDown: {
            if (!_simulateHoldEvents) { break; }

            [(NSTimer *)attributes[kHIDRemoteSimulateHoldEventsTimer] invalidate];

            if (isPressed) {
                attributes[kHIDRemoteSimulateHoldEventsOriginButtonCode] = @(buttonCode);
                let holdTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.7] interval:0.1 target:self selector:@selector(_simulateHoldEvent:) userInfo:attributes repeats:NO];
                attributes[kHIDRemoteSimulateHoldEventsTimer] = holdTimer;
                [[NSRunLoop currentRunLoop] addTimer:holdTimer forMode:NSRunLoopCommonModes];
                break;
            } else {
                let holdTimer = (NSTimer *)attributes[kHIDRemoteSimulateHoldEventsTimer];
                let buttonCodeValue = (NSNumber *)attributes[kHIDRemoteSimulateHoldEventsOriginButtonCode];
                let originButtonCode = (HIDRemoteButtonCode)buttonCodeValue.unsignedIntValue;

                if (holdTimer && buttonCodeValue) {
                    [self _sendButtonCode:originButtonCode isPressed:YES attributes:attributes];
                    [self _sendButtonCode:originButtonCode isPressed:NO attributes:attributes];
                } else if (buttonCodeValue != nil) {
                    [self _sendButtonCode:(originButtonCode | kHIDRemoteButtonCodeHoldMask) isPressed:NO attributes:attributes];
                }
            }

            [attributes removeObjectForKey:kHIDRemoteSimulateHoldEventsTimer];
            [attributes removeObjectForKey:kHIDRemoteSimulateHoldEventsOriginButtonCode];
        } break;
		
        default: {
            [self _sendButtonCode:buttonCode isPressed:isPressed attributes:attributes];
        }
	}
}

- (void)_sendButtonCode:(HIDRemoteButtonCode)buttonCode isPressed:(BOOL)isPressed attributes:(HIDServiceAttributes *)attributes {
    if (![self.delegate respondsToSelector:@selector(hidRemote:eventWithButton:isPressed:fromHardwareWithAttributes:)]) {
        return;
    }

    switch (buttonCode & (~kHIDRemoteButtonCodeAluminumMask)) {
        case kHIDRemoteButtonCodePlay:
        case kHIDRemoteButtonCodeCenter: {
            if (buttonCode & kHIDRemoteButtonCodeAluminumMask) {
                _lastSeenModel = kHIDRemoteModelAluminum;
                _lastSeenModelRemoteID = _lastSeenRemoteID;
            } else {
                let supportLevel = (HIDRemoteAluminumRemoteSupportLevel)[(NSNumber *)attributes[kHIDRemoteAluminumRemoteSupportLevel] intValue];
                switch (supportLevel) {
                    case kHIDRemoteAluminumRemoteSupportLevelNone:
                    case kHIDRemoteAluminumRemoteSupportLevelEmulation: {
                        // Remote type can't be determined by just the Center button press
                    } break;

                    case kHIDRemoteAluminumRemoteSupportLevelNative: {
                        // Remote type can be safely determined by just the Center button press
                        if (((_lastSeenModel == kHIDRemoteModelAluminum) && (_lastSeenModelRemoteID != _lastSeenRemoteID)) ||
                            (_lastSeenModel == kHIDRemoteModelUndetermined)) {
                            _lastSeenModel = kHIDRemoteModelWhitePlastic;
                        }
                    } break;
                }
            }
        } break;
    }

    // As soon as we have received a code that's unique to the Aluminum Remote, we can tell kHIDRemoteButtonCodePlayHold and kHIDRemoteButtonCodeCenterHold apart.
    // Prior to that, a long press of the new "Play" button will be submitted as a "kHIDRemoteButtonCodeCenterHold", not a "kHIDRemoteButtonCodePlayHold" code.
    if ((buttonCode == kHIDRemoteButtonCodeCenterHold) && (_lastSeenModel == kHIDRemoteModelAluminum)) {
        buttonCode = kHIDRemoteButtonCodePlayHold;
    }

    [((NSObject <HIDRemoteDelegate> *)self.delegate) hidRemote:self
                                               eventWithButton:(buttonCode & (~kHIDRemoteButtonCodeAluminumMask))
                                                     isPressed:isPressed
                                    fromHardwareWithAttributes:attributes];
}

- (void)_hidEventFor:(io_service_t)hidDevice from:(IOHIDQueueInterface **)interface withResult:(IOReturn)result {
	let hidAttributes = _servicesMap[@(hidDevice)];
    if (hidAttributes == nil) { return; }
    let attr = (MutableHIDServiceAttributes *)hidAttributes;

    let queueInterface = (IOHIDQueueInterface **)[attr[kHIDRemoteHIDQueueInterface] pointerValue];
    if (interface == queueInterface) {
        let buttonCookies = (NSDictionary *)attr[kHIDRemoteCookieButtonCodeLUT];
        var lastButtonPressed = (HIDRemoteButtonCode)((NSNumber *)attr[kHIDRemoteLastButtonPressed]).unsignedIntValue;

        while (result == kIOReturnSuccess) {
            IOHIDEventStruct hidEvent;
            AbsoluteTime supportedTime = { 0,0 };

            result = (*queueInterface)->getNextEvent(queueInterface, &hidEvent, supportedTime, 0);

            if (result == kIOReturnSuccess) {
                let buttonCodeValue = (NSNumber *)buttonCookies[@(hidEvent.elementCookie)];

                #ifdef _HIDREMOTE_EXTENSIONS
                    // Debug logging code
                    #define _HIDREMOTE_EXTENSIONS_SECTION 5
                    #include "HIDRemoteAdditions.h"
                    #undef _HIDREMOTE_EXTENSIONS_SECTION
                #endif /* _HIDREMOTE_EXTENSIONS */

                if (buttonCodeValue != nil) {
                    let buttonCode = (HIDRemoteButtonCode)buttonCodeValue.unsignedIntValue;

                    if (hidEvent.value == 0 && buttonCode == lastButtonPressed) {
                        [self _handleButtonCode:lastButtonPressed isPressed:NO attributes:attr];
                        lastButtonPressed = kHIDRemoteButtonCodeNone;
                    }

                    if (hidEvent.value != 0) {
                        if (lastButtonPressed != kHIDRemoteButtonCodeNone) {
                            [self _handleButtonCode:lastButtonPressed isPressed:NO attributes:attr];
                        }

                        if (buttonCode == kHIDRemoteButtonCodeIDChanged) {
                            if ([self.delegate respondsToSelector:@selector(hidRemote:remoteIDChangedOldID:newID:forHardwareWithAttributes:)]) {
                                [((NSObject <HIDRemoteDelegate> *)self.delegate) hidRemote:self
                                                                      remoteIDChangedOldID:_lastSeenRemoteID
                                                                                     newID:hidEvent.value
                                                                 forHardwareWithAttributes:attr];
                            }

                            _lastSeenRemoteID = hidEvent.value;
                            _lastSeenModel	  = kHIDRemoteModelUndetermined;
                        }

                        [self _handleButtonCode:buttonCode isPressed:YES attributes:attr];
                        lastButtonPressed = buttonCode;
                    }
                }
            }
        }

        let attrCopy = (NSMutableDictionary *)attr.mutableCopy;
        attrCopy[kHIDRemoteLastButtonPressed] = @(lastButtonPressed);
        _servicesMap[@(hidDevice)] = attrCopy.copy;
    }

    #ifdef _HIDREMOTE_EXTENSIONS
        // Debug logging code
        #define _HIDREMOTE_EXTENSIONS_SECTION 6
        #include "HIDRemoteAdditions.h"
        #undef _HIDREMOTE_EXTENSIONS_SECTION
    #endif /* _HIDREMOTE_EXTENSIONS */
}

#pragma mark - PRIVATE: Notification handling
- (void)_serviceMatching:(io_iterator_t)iterator {
	var matchingService = (io_object_t)0;
	while ((matchingService = IOIteratorNext(iterator)) != 0) {
		[self _setupService:matchingService];
		IOObjectRelease(matchingService);
	}
}

- (void)_serviceNotificationFor:(io_service_t)service messageType:(natural_t)messageType messageArgument:(void * __unused)messageArgument {
	if (messageType == kIOMessageServiceIsTerminated) {
		[self _destructService:service];
	}
}

- (void)_updateSessionInformation {
    if (_masterPort == 0) { return; }

    let rootService = IORegistryGetRootEntry(_masterPort);
    if (rootService == 0) { return; }

    let consoleUsers = (__bridge_transfer NSArray<NSDictionary<NSString *, id> *> *)IORegistryEntryCreateCFProperty(rootService, kIOConsoleUsers, kCFAllocatorDefault, 0);

    if (![consoleUsers isKindOfClass:NSArray.class]) {
        IOObjectRelease((io_object_t)rootService);
        return;
    }

    NSUInteger secureEventInputPIDSum = 0;
    uid_t frontUserSession = 0;
    BOOL screenIsLocked = NO;

    for (NSDictionary<NSString *, id> *consoleUser in consoleUsers) {
        if (![consoleUser isKindOfClass:NSDictionary.class]) { continue; }

        let secureInputPID = (NSNumber *)consoleUser[kCGSSessionSecureInputPID];
        if ([secureInputPID isKindOfClass:NSNumber.class]) {
            secureEventInputPIDSum += (UInt64)secureInputPID.unsignedIntValue;
        }

        let onConsole = (NSNumber *)consoleUser[kCGSSessionOnConsoleKey];
        let userID = (NSNumber *)consoleUser[kCGSSessionUserIDKey];
        if ([onConsole isKindOfClass:NSNumber.class] && [userID isKindOfClass:NSNumber.class] && onConsole.boolValue) {
            frontUserSession = (uid_t)userID.unsignedIntValue;
        }

        let screenIsLockedBool = (NSNumber *)consoleUser[CGSSessionScreenIsLocked];
        if ([screenIsLockedBool isKindOfClass:NSNumber.class]) {
            screenIsLocked = screenIsLockedBool.boolValue;
        }
    }

    _lastSecureEventInputPIDSum = secureEventInputPIDSum;
    _lastFrontUserSession = frontUserSession;
    _lastScreenIsLocked = screenIsLocked;

    IOObjectRelease((io_object_t)rootService);
}

- (void)_silentRestart {
	if ((_mode == kHIDRemoteModeExclusive) || (_mode == kHIDRemoteModeExclusiveAuto)) {
		let restartInMode = _mode;
		let checkActiveRemoteControlCount = self.activeRemoteControlCount;
		
		// Only restart when we already have active remote controls - to avoid race conditions with other applications using kHIDRemoteModeExclusive mode (new in V1.2.1)
		if (checkActiveRemoteControlCount > 0) {
			_isRestarting = YES;
			[self stopRemoteControl];
			[self startRemoteControl:restartInMode];
			_isRestarting = NO;
			
			// Check whether we lost a remote control due to restarting/secure input change notification handling (new in V1.2.1)
			if (checkActiveRemoteControlCount != self.activeRemoteControlCount) {
                NSLog(@"Lost access (mode %lu) to %lu IR Remote Receiver(s) after handling SecureInput change notification - please quit other apps trying to use the Remote exclusively", restartInMode, checkActiveRemoteControlCount);
			}
		}
	}
}

- (void)_secureInputNotificationFor:(io_service_t __unused)service messageType:(natural_t)messageType messageArgument:(void * __unused)messageArgument {
	if (messageType == kIOMessageServiceBusyStateChange) {
        let old_lastSecureEventInputPIDSum = _lastSecureEventInputPIDSum;
        let old_lastFrontUserSession = _lastFrontUserSession;
        let old_lastScreenIsLocked = _lastScreenIsLocked;
		
		[self _updateSessionInformation];
		
		if (((old_lastSecureEventInputPIDSum != _lastSecureEventInputPIDSum) ||
		     (old_lastFrontUserSession != _lastFrontUserSession) ||
		     (old_lastScreenIsLocked != _lastScreenIsLocked)) && _enableSecureEventInputWorkaround) {
			[self _silentRestart];
		}
	}
}

- (void)_computerDidWake:(NSNotification *)note {
    #if HIDREMOTE_THREADSAFETY_HARDENED_NOTIFICATION_HANDLING
    // OS X 10.5+ only
    if ([self respondsToSelector:@selector(performSelector:onThread:withObject:waitUntilDone:)]) {
        if ([NSThread currentThread] != _runOnThread) {
            [self performSelector:@selector(_computerDidWake:) onThread:_runOnThread withObject:note waitUntilDone:NO];
            return;
        }
    }
    #endif

    [self _silentRestart];
}

@end

#pragma mark - PRIVATE: IOKitLib Callbacks

static void HIDEventCallback(void *target, IOReturn result, void *refCon, void *sender) {
    let hidRemote = (__bridge HIDRemote *)refCon;
    @autoreleasepool {
        [hidRemote _hidEventFor:(io_service_t)((intptr_t)target) from:(IOHIDQueueInterface**)sender withResult:(IOReturn)result];
    }
}


static void ServiceMatchingCallback(void *refCon, io_iterator_t iterator) {
	let hidRemote = (__bridge HIDRemote *)refCon;
    @autoreleasepool {
        [hidRemote _serviceMatching:iterator];
    }
}

static void ServiceNotificationCallback(void *refCon, io_service_t service, natural_t messageType, void *messageArgument) {
    let hidRemote = (__bridge HIDRemote *)refCon;
	@autoreleasepool {
        [hidRemote _serviceNotificationFor:service
                       messageType:messageType
                   messageArgument:messageArgument];
	}
}

static void SecureInputNotificationCallback(void * refCon, io_service_t service, natural_t messageType, void *messageArgument) {
    let hidRemote = (__bridge HIDRemote *)refCon;
    @autoreleasepool {
        [hidRemote _secureInputNotificationFor:service
                                   messageType:messageType
                               messageArgument:messageArgument];
    }
}

NS_ASSUME_NONNULL_END
