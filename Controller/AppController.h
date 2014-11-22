//
//  AppController.h
//  DictPod
//
//  Created by Michael Bianco on 3/9/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "shared.h"

//URL's
#define HOME_URL @"http://prosit-software.com/"
#define BUG_URL @"http://prosit-software.com/contact.html?type=bug&prod=idict"
#define PURCHASE_URL @"http://prosit-software.com/idictionary.html#purchase"
#define SUPPORT_URL @"http://prosit-software.com/contact.html?type=support&prod=idict"
#define IDICTIONARY_URL @"http://prosit-software.com/idictionary.html"

#ifdef HIDDEN_FILES
#define LICENSE_FILE_NAME @".license"
#else 
#define LICENSE_FILE_NAME @"license"
#endif

#define LICENSE_FILE_EXT @"idictionarylicense"

@interface AppController : NSObject {
	IBOutlet NSWindow *oBuyWindow, *oLicenseInfoWindow, *oCreationWindow;
	IBOutlet NSButton *oBuyButton;
	IBOutlet NSMenuItem *oBuyMenuItem, *oLicenseInfo, *oLoadLicense;
	NSMenu *_aboutMenu;
	IBOutlet NSTextField *oLicenseName, *oLicenseEmail, *oLicenseDate;
	
	NSWindowController *_prefController, *_createdDictionariesController;
}

+(AppController *) sharedController;

//-----------------------
//	Action Methods
//-----------------------
- (IBAction) purchaseNow:(id)sender;
- (IBAction) putchaseLater:(id)sender;
- (IBAction) reportBug:(id)sender;
- (IBAction) contactSupport:(id)sender;
- (IBAction) goToHomePage:(id)sender;
- (IBAction) licenseAgreement:(id)sender;
- (IBAction) openPreferences:(id)sender;
- (IBAction) openCreatedDictionaries:(id)sender;
- (IBAction) loadLicense:(id)sender;
- (IBAction) licenseInformation:(id)sender;

- (BOOL) validateMenuItem:(id <NSMenuItem>)menuItem;
- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename;

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void) applicationWillTerminate:(NSNotification *)aNotification;
- (void) applicationRegistered:(NSNotification *)note;
@end
