//
//  ViewController.swift
//  HIDRemoteExample
//
//  Created by Alex Nazarov on 24/10/2022.
//

import Foundation
import Cocoa

class DemoController: NSObject, HIDRemoteDelegate {

    @IBOutlet var logWindow: NSWindow!

    @IBOutlet var logTableView: NSTableView!
    @IBOutlet var logArrayController: NSArrayController!
    @IBOutlet var modeButton: NSPopUpButton!
    @IBOutlet var startStopButton: NSButton!
    @IBOutlet var enableExclusiveLockLending: NSButton!
    @IBOutlet var statusImageView: NSImageView!

//    let buttonImageMap: [;
    private lazy var hidRemote: HIDRemote = {
        let remote = HIDRemote()
        remote.delegate = self
        return remote
    }()

    private var buttonImageLastShownPress: TimeInterval = 0
    private var delayReleaseDisplayTimer: Timer?

    override func awakeFromNib() {
        super.awakeFromNib()
        //    if (!buttonImageMap) {
        //        if ((buttonImageMap = [[NSMutableDictionary alloc] init]) != nil) {
        //            [self addImageNamed:@"remoteButtonUp"     forButtonCode:kHIDRemoteButtonCodeUp];
        //            [self addImageNamed:@"remoteButtonDown"   forButtonCode:kHIDRemoteButtonCodeDown];
        //            [self addImageNamed:@"remoteButtonLeft"   forButtonCode:kHIDRemoteButtonCodeLeft];
        //            [self addImageNamed:@"remoteButtonRight"  forButtonCode:kHIDRemoteButtonCodeRight];
        //            [self addImageNamed:@"remoteButtonSelect" forButtonCode:kHIDRemoteButtonCodeCenter];
        //            [self addImageNamed:@"remoteButtonMenu"   forButtonCode:kHIDRemoteButtonCodeMenu];
        //            [self addImageNamed:@"remoteButtonPlay"   forButtonCode:kHIDRemoteButtonCodePlay];
        //            [self addImageNamed:@"remoteButtonNone"   forButtonCode:kHIDRemoteButtonCodeNone];
        //        }
        //    }
        //
        //    // Set up remote control
        //    [self setupRemote];
        //    [self appendToLog:@"Launched"];
        //    [self displayImageForButtonCode:kHIDRemoteButtonCodeNone allowReleaseDisplayDelay:NO];
    }

    deinit {
        if (hidRemote.isStarted) {
            hidRemote.stopControl()
        }

        hidRemote.delegate = nil
    }

    func hidRemote(_ hidRemote: HIDRemote, eventWithButton buttonCode: HIDRemoteButtonCode, isPressed: Bool, fromHardwareWithAttributes attributes: [String : Any] = [:]) {

    }

    func hidRemote(_ hidRemote: HIDRemote, remoteIDChangedOldID old: Int32, newID: Int32, forHardwareWithAttributes attributes: [String : Any] = [:]) {
        appendToLog("Change of remote ID from \(old) to \(newID) (for \(attributes[kHIDRemoteProduct]) by \(attributes[kHIDRemoteManufacturer]) (Transport: \( attributes[kHIDRemoteTransport])))")
    }

    //- (void)hidRemote:(HIDRemote *)aHidRemote remoteIDChangedOldID:(SInt32)old newID:(SInt32)newID forHardwareWithAttributes:(NSMutableDictionary *)attributes {
    //    [self appendToLog:[NSString stringWithFormat:@"Change of remote ID from %d to %d (for %@ by %@ (Transport: %@))", (int)old, (int)newID, attributes[kHIDRemoteProduct], attributes[kHIDRemoteManufacturer], attributes[kHIDRemoteTransport]]];
    //}
    //
    //// Notification about hardware additions/removals
    //- (void)hidRemote:(HIDRemote *)aHidRemote foundNewHardwareWithAttributes:(NSMutableDictionary *)attributes {
    //    [self appendToLog:[NSString stringWithFormat:@"Found hardware: %@ by %@ (Transport: %@)", attributes[kHIDRemoteProduct], attributes[kHIDRemoteManufacturer], attributes[kHIDRemoteTransport]]];
    //}
    //
    //- (void)hidRemote:(HIDRemote *)aHidRemote failedNewHardwareWithError:(NSError *)error {
    //    [self appendToLog:[NSString stringWithFormat:@"Initialization of hardware failed with error %@ (%@)", error.localizedDescription, error.userInfo[@"InternalErrorCode"]]];
    //}
    //
    //- (void)hidRemote:(HIDRemote *)aHidRemote releasedHardwareWithAttributes:(NSMutableDictionary *)attributes {
    //    [self appendToLog:[NSString stringWithFormat:@"Released hardware: %@ by %@ (Transport: %@)", attributes[kHIDRemoteProduct], attributes[kHIDRemoteManufacturer], attributes[kHIDRemoteTransport]]];
    //}
    //
    //#pragma mark -- HID Remote code (usage of optional expert, special purpose features) --
    //- (BOOL)hidRemote:(HIDRemote *)aHidRemote lendExclusiveLockToApplicationWithInfo:(NSDictionary *)applicationInfo {
    //    [self appendToLog:[NSString stringWithFormat:@"Lending exclusive lock to %@ (pid %@)", applicationInfo[(id)kCFBundleIdentifierKey], applicationInfo[kHIDRemoteDNStatusPIDKey]]];
    //
    //    return (YES);
    //}

    //
    //- (void)hidRemote:(HIDRemote *)aHidRemote exclusiveLockReleasedByApplicationWithInfo:(NSDictionary *)applicationInfo {
    //    [self appendToLog:[NSString stringWithFormat:@"Exclusive lock released by %@ (pid %@)", applicationInfo[(id)kCFBundleIdentifierKey], applicationInfo[kHIDRemoteDNStatusPIDKey]]];
    //    [aHidRemote startRemoteControl:kHIDRemoteModeExclusive];
    //}
    //
    //- (BOOL)hidRemote:(HIDRemote *)aHidRemote shouldRetryExclusiveLockWithInfo:(NSDictionary *)applicationInfo {
    //    [self appendToLog:[NSString stringWithFormat:@"%@ (pid %@) says I should retry to acquire exclusive locks", applicationInfo[(id)kCFBundleIdentifierKey], applicationInfo[kHIDRemoteDNStatusPIDKey]]];
    //
    //    return (YES);
    //}

    func buttonName(for code: HIDRemoteButtonCode) -> String {
        switch code {
        case .up:
            return "Up"
        case .down:
            return "Down"
        case .left:
            return "Left"
        case .right:
            return "Right"
        case .center:
            return "Center"
        case .play:
            return "Play/Pause"
        case .menu:
            return "Menu"
        case .upHold:
            return "Up (hold)"
        case .downHold:
            return "Down (hold)"
        case .leftHold:
            return "Left (hold)"
        case .rightHold:
            return "Right (hold)"
        case .centerHold:
            return "Center (hold)"
        case .playHold:
            return "Play/Pause (hold)"
        case .menuHold:
            return "Menu (hold)"
        default:
            return "Button \(code)"
        }
    }

    func appendToLog(_ msg: String) {
        logArrayController.add(["timeStamp": Date().description, "logText": msg])
        logTableView.scrollRowToVisible((logArrayController.arrangedObjects as! [Any]).count - 1)
    }
}

//
//- (void)hidRemote:(HIDRemote *)theHidRemote eventWithButton:(HIDRemoteButtonCode)buttonCode isPressed:(BOOL)isPressed fromHardwareWithAttributes:(NSMutableDictionary *)attributes {
//    NSString *remoteModel = nil;
//
//    switch ([theHidRemote lastSeenModel]) {
//        case kHIDRemoteModelUndetermined:
//            remoteModel = [NSString stringWithFormat:@"Undetermined:%d", (int)[theHidRemote lastSeenRemoteControlID]];
//        break;
//
//        case kHIDRemoteModelAluminum:
//            remoteModel = [NSString stringWithFormat:@"Aluminum:%d", (int)[theHidRemote lastSeenRemoteControlID]];
//        break;
//
//        case kHIDRemoteModelWhitePlastic:
//            remoteModel = [NSString stringWithFormat:@"White Plastic:%d", (int)[theHidRemote lastSeenRemoteControlID]];
//        break;
//    }
//
//    if (isPressed) {
//        [self appendToLog:[NSString stringWithFormat:@"%@ pressed (%@, %@)", [self buttonNameForButtonCode:buttonCode], remoteModel, attributes[kHIDRemoteProduct]]];
//        [self displayImageForButtonCode:buttonCode allowReleaseDisplayDelay:NO];
//    } else {
//        [self appendToLog:[NSString stringWithFormat:@"%@ released (%@, %@)", [self buttonNameForButtonCode:buttonCode], remoteModel, attributes[kHIDRemoteProduct]]];
//        [self displayImageForButtonCode:kHIDRemoteButtonCodeNone allowReleaseDisplayDelay:YES];
//    }
//}

//#pragma mark -- HID Remote code (usage of optional features) --


//#pragma mark -- UI code --
//- (void)addImageNamed:(NSString *)imageName forButtonCode:(HIDRemoteButtonCode)buttonCode {
//    NSString *imagePath;
//
//    if ((imagePath = [[NSBundle mainBundle] pathForImageResource:imageName]) != nil) {
//        NSImage *loadedImage;
//
//        if ((loadedImage = [[NSImage alloc] initWithContentsOfFile:imagePath]) != nil) {
//            buttonImageMap[@((unsigned int)buttonCode)] = loadedImage;
//            [loadedImage release];
//        }
//    }
//}

//
//- (void)displayImageForButtonCode:(HIDRemoteButtonCode)buttonCode allowReleaseDisplayDelay:(BOOL)doAllowReleaseDisplayDelay {
//    HIDRemoteButtonCode basicCode;
//    NSImage *image;
//
//    if (delayReleaseDisplayTimer) {
//        [delayReleaseDisplayTimer invalidate];
//        [delayReleaseDisplayTimer release];
//        delayReleaseDisplayTimer = nil;
//    }
//
//    if (buttonCode == kHIDRemoteButtonCodeNone)
//    {
//        if (doAllowReleaseDisplayDelay && (buttonImageLastShownPress != 0.0))
//        {
//            if (([NSDate timeIntervalSinceReferenceDate] - buttonImageLastShownPress) < 0.10)
//            {
//                delayReleaseDisplayTimer = [[NSTimer scheduledTimerWithTimeInterval:0.10 target:self selector:@selector(displayDefaultImage:) userInfo:nil repeats:NO] retain];
//                return;
//            }
//        }
//    }
//    else
//    {
//        buttonImageLastShownPress = [NSDate timeIntervalSinceReferenceDate];
//    }
//
//    basicCode = buttonCode & kHIDRemoteButtonCodeCodeMask;
//
//    if ((image = buttonImageMap[[NSNumber numberWithUnsignedInt:basicCode]]) != nil)
//    {
//        statusImageView.image = image;
//    }
//}
//
//- (void)displayDefaultImage:(NSTimer *)aTimer
//{
//    [self displayImageForButtonCode:kHIDRemoteButtonCodeNone allowReleaseDisplayDelay:NO];
//}
//
//- (IBAction)startStopRemote:(id)sender {
//    // Has the HID Remote already been started?
//    if ([hidRemote isStarted]) {
//        // HID Remote already started. Stop it.
//        [hidRemote stopRemoteControl];
//        startStopButton.title = @"Start";
//        [modeButton setEnabled:YES];
//        [self appendToLog:@"-- Stopped HID Remote --"];
//    } else {
//        // HID Remote has not been started yet. Start it.
//        HIDRemoteMode remoteMode = kHIDRemoteModeNone;
//        NSString *remoteModeName = nil;
//
//        // Fancy GUI stuff
//        switch (modeButton.indexOfSelectedItem) {
//            case 0:
//                remoteMode = kHIDRemoteModeShared;
//                remoteModeName = @"shared";
//            break;
//
//            case 1:
//                remoteMode = kHIDRemoteModeExclusive;
//                remoteModeName = @"exclusive";
//            break;
//
//            case 2:
//                remoteMode = kHIDRemoteModeExclusiveAuto;
//                remoteModeName = @"exclusive (auto)";
//            break;
//        }
//
//        // Check whether the installation of Candelair is required to reliably operate in this mode
//        if ([HIDRemote isCandelairInstallationRequiredForRemoteMode:remoteMode]) {
//            // Reliable usage of the remote in this mode under this operating system version
//            // requires the Candelair driver to be installed. Tell the user about it.
//            #pragma clang diagnostic push
//            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
//            NSAlert *alert;
//
//            if ((alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Candelair driver installation necessary", @"")
//                                         defaultButton:NSLocalizedString(@"Download", @"")
//                           alternateButton:NSLocalizedString(@"More information", @"")
//                               otherButton:NSLocalizedString(@"Cancel", @"")
//                     informativeTextWithFormat:NSLocalizedString(@"An additional driver needs to be installed before %@ can reliably access the remote under the OS version installed on your computer.", @""), [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleNameKey]]) != nil) {
//                switch ([alert runModal]) {
//                    case NSAlertDefaultReturn:
//                        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.candelair.com/download/"]];
//                    break;
//
//                    case NSAlertAlternateReturn:
//                        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.candelair.com/"]];
//                    break;
//                }
//            }
//            #pragma clang diagnostic pop
//        } else {
//            // Candelair is either already installed or not required under this OS release => proceed!
//            if ([hidRemote startRemoteControl:remoteMode]) {
//                // Start was successful, perform UI changes and log it.
//                [self appendToLog:[NSString stringWithFormat:@"-- Starting HID Remote in %@ mode (OS X %lx) successful --", remoteModeName, (unsigned long)[HIDRemote OSXVersion]]];
//                startStopButton.title = @"Stop";
//                [modeButton setEnabled:NO];
//            } else {
//                // Start failed. Log about it
//                [self appendToLog:[NSString stringWithFormat:@"Starting HID Remote in %@ mode failed", remoteModeName]];
//            }
//        }
//    }
//}
//
//- (BOOL)windowShouldClose:(id)window {
//    [[NSApplication sharedApplication] terminate:self];
//    return (YES);
//}
//
//- (IBAction)showHideELLCheckbox:(id)sender {
//    // Exclusive mode selected
//    if (modeButton.indexOfSelectedItem == 1) {
//        [enableExclusiveLockLending setHidden:NO];
//    } else {
//        [enableExclusiveLockLending setHidden:YES];
//    }
//}
//
//- (IBAction)enableExclusiveLockLending:(id)sender {
//    if ([sender state] == NSOnState) {
//        [self appendToLog:@"Exclusive Lock Lending enabled"];
//        [hidRemote setExclusiveLockLendingEnabled:YES];
//    } else {
//        [self appendToLog:@"Exclusive Lock Lending disabled"];
//        [hidRemote setExclusiveLockLendingEnabled:NO];
//    }
//}
