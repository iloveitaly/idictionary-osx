//
//  AppController.m
//  DictPod
//
//  Created by Michael Bianco on 3/9/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import "Preferences.h"
#import "RegistrationHandling.h"
#import "AquaticPrime.h"
#import "AppSupportController.h"
#import "CreatedDictionariesController.h"
#import "shared.h"

static AppController *_sharedController;

@implementation AppController
+(void) initialize {
	//set the default preference values
	NSDictionary *defaults = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], nil]
														 forKeys:[NSArray arrayWithObjects:AUTO_OPEN_MAIN_WINDOW, SLOW_DICTIONARY_CREATION, nil]];
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaults];
}

+(AppController *) sharedController {
	extern AppController *_sharedController;
	return _sharedController;
}

- (id) init {
	if (self = [super init]) {
		extern AppController *_sharedController;
		_sharedController = self;
		
		[NSApp setDelegate:self];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationRegistered:)
													 name:MABAppRegisteredNotification
												   object:nil];
	}
	
	return self;
}

-(void) awakeFromNib {
	[oBuyMenuItem retain];
	[oLicenseInfo retain];
	[oLoadLicense retain];
}

-(IBAction) purchaseNow:(id)sender {
	[oBuyWindow close];
	OPEN_URL(PURCHASE_URL); 
}

-(IBAction) putchaseLater:(id)sender {
	[oBuyWindow close];
}

-(IBAction) reportBug:(id)sender {
	OPEN_URL(BUG_URL);
}

- (IBAction) contactSupport:(id)sender {
	OPEN_URL(SUPPORT_URL);
}

-(IBAction) goToHomePage:(id)sender {
	OPEN_URL(HOME_URL);
}

-(IBAction) licenseAgreement:(id)sender {
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"License" ofType:@"rtf"]];
}

-(IBAction) openPreferences:(id)sender {
	if(!_prefController) {
		_prefController = [[NSWindowController alloc] initWithWindowNibName:@"Preferences"];
	}
	
	[_prefController showWindow:self];
}

-(IBAction) openCreatedDictionaries:(id)sender {
	if(!_createdDictionariesController) {
		_createdDictionariesController = [[CreatedDictionariesController alloc] initWithWindowNibName:@"CreatedDictionaries"];
	}
	
	[_createdDictionariesController showWindow:self];	
}

- (IBAction) loadLicense:(id)sender {
	RunLoadLicensePanel();
}

- (IBAction) licenseInformation:(id)sender {
	NSDictionary *license = LicenseDictionary();
	
	[oLicenseName setStringValue:[license valueForKey:@"Name"]];
	[oLicenseEmail setStringValue:[license valueForKey:@"Email"]];
	
	if(!isEmpty([license valueForKey:@"Date"])) {
		[oLicenseDate setStringValue:[license valueForKey:@"Date"]];
	} else {
		[oLicenseDate setStringValue:NSLocalizedString(@"Not Specified", nil)];
	}
	
	[oLicenseInfoWindow makeKeyAndOrderFront:self];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	if(menuItem == oLicenseInfo) {//validate the license information menu item
		return LicenseDictionary() != nil;
	}
		
	return YES;
}

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename {
	if(IsRegistered()) {//isRegistered() also sets up all the keys and stuff
		NSLog(@"Application is already registered! No need to re-register it!");
		return NO;
	}
	
	NSURL *licenseURL = [NSURL fileURLWithPath:filename];
	if(APCreateDictionaryForLicenseFile((CFURLRef)licenseURL) != nil) {
		[[AppSupportController sharedController] createSupportFolder];
		
		if(![[NSFileManager defaultManager] copyPath:filename 
											  toPath:[[[AppSupportController sharedController] supportFolder] stringByAppendingPathComponent:LICENSE_FILE_NAME]
											 handler:nil]) {
			NSLog(@"Error copying license file");	
		}
		
		RunSuccessfulLicenseAlert();
		
		//let everybody know iDictionary is registered!
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:MABAppRegisteredNotification object:nil]];
		return YES;
	} else {
		RunInvalidLicenseAlert();
		return NO;	
	}
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
	//this method should only be called at the start of the application
	
	if(![[NSBundle mainBundle] pathForResource:@"helper" ofType:@""] || //check to make sure we have the helper application
	   !oBuyWindow ||													//and the buy now window
	   ![[NSBundle mainBundle] pathForResource:@"buynow" ofType:@"txt"]) {//and the buynow text file
		
		NSLog(@"No helper tool found!");
		
		if(NSRunAlertPanel(NSLocalizedString(@"Corrupt Application", nil),
						   NSLocalizedString(@"You have a corrupt application, please download the latest version from our website. Would you like to go to the download page now?", nil),
						   NSLocalizedString(@"Yes", nil), NSLocalizedString(@"No", nil), nil) == NSOKButton) {//take them to the website!
			OPEN_URL(IDICTIONARY_URL);
		}
		
		[NSApp terminate:self];
		return;
	}
	
	
	//remove them, but they are retained in -awakeFromNib so we can add them if the app is registered
	[_aboutMenu = [oLicenseInfo menu] removeItem:oLicenseInfo];
	
	if(IsRegistered()) {
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:MABAppRegisteredNotification object:nil]];
	} else {
		[oBuyWindow makeKeyAndOrderFront:self]; //bring the BUY NOW window to the front
		[oBuyWindow setDefaultButtonCell:[oBuyButton cell]]; //set the default button cell
	}
}

-(void) applicationRegistered:(NSNotification *) note {	
	[[oBuyMenuItem menu] removeItem:oBuyMenuItem]; //remove the buy menu item since its already bought
	[[oLoadLicense menu] removeItem:oLoadLicense]; //remove the load license menu item, since a license has already been loaded
	[_aboutMenu insertItem:oLicenseInfo atIndex:5]; //index 5 is after the seperator after the 'preferences' item
}

-(void) applicationWillBecomeActive:(NSNotification *)aNotification {
	if(PREF_KEY_BOOL(AUTO_OPEN_MAIN_WINDOW) && ![NSApp keyWindow]) {
		[oCreationWindow makeKeyAndOrderFront:self];
	}
}

-(void) applicationWillTerminate:(NSNotification *)aNotification {
	//NSLog(@"will die");
}
@end
