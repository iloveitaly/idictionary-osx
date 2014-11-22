/*
 *  RegistrationHandling.c
 *  DictPod
 *
 *  Created by Michael Bianco on 3/15/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import "RegistrationHandling.h"
#import "AquaticPrime.h"
#import "AppSupportController.h"
#import "AppController.h"
#import "shared.h"

#import <CoreFoundation/CoreFoundation.h>

#ifdef HIDDEN_LICENSE_FUNCTIONS
static NSDictionary *_someCoolDictionary = nil;
#define _licenseDictionary _someCoolDictionary
#else
static NSDictionary *_licenseDictionary = nil;
#endif

int RunInvalidLicenseAlert(void) {
	int result = NSRunAlertPanel(NSLocalizedString(@"Invalid License", nil),
								 NSLocalizedString(@"The license file you have chosen is invalid. If you know you have a valid license file, please contact customer support and we will resolve this issue. If you haven't yet purchased a license file, you can do so at our web-site.", nil),
								 NSLocalizedString(@"Buy License", nil),
								 NSLocalizedString(@"Contact Support", nil),
								 NSLocalizedString(@"Buy Later", nil));
	
	switch(result) {
		case NSAlertDefaultReturn: //then they want to buy the license
			OPEN_URL(PURCHASE_URL);
			break;
		case NSAlertAlternateReturn: //then they want to contact support
			OPEN_URL(SUPPORT_URL);
			break;
	}
	
	return result;
}

int RunSuccessfulLicenseAlert(void) {
	return NSRunInformationalAlertPanel(NSLocalizedString(@"Success!", nil),
										NSLocalizedString(@"iDictionary has been successfully licensed.", nil),
										nil, nil, nil);	
}

void RunLoadLicensePanel(void) {
	//make an open file dialog to load the license file
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	
	if([panel runModalForTypes:[NSArray arrayWithObject:LICENSE_FILE_EXT]] == NSOKButton) {//choose a license file
		//get the path of file chosen
		NSString *licenseFile = [[panel filenames] objectAtIndex:0];
		
		if(APCreateDictionaryForLicenseFile((CFURLRef)[NSURL fileURLWithPath:licenseFile]) != nil) {//successfull validation of the license
			[[AppSupportController sharedController] createSupportFolder];
			
			if(![[NSFileManager defaultManager] copyPath:licenseFile 
												  toPath:[[[AppSupportController sharedController] supportFolder] stringByAppendingPathComponent:LICENSE_FILE_NAME]
												 handler:nil]) {
				NSLog(@"Error copying license file");
				return;
			}
			
			if(!IsRegistered()) {//check again, just in case, just to make sure the license file chosen is a valid license
				RunInvalidLicenseAlert();
			} else {//the license loaded was a valid license
				RunSuccessfulLicenseAlert();
				
				//reconfigure the menu items and notify any observers that we are registered!
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:MABAppRegisteredNotification object:nil]];
			}
		} else {//then their was an error validating the license
			RunInvalidLicenseAlert();
			return;	
		}
	} else {//didn't choose a license
		//maybe show another alert panel here asking the user to buy a license?
		return;
	}				
}

int RunBuyNowAlert(void) {
	//maybe do this in the future, it would make it easier to handle different license situations
	return 0;
}

#ifdef HIDDEN_LICENSE_FUNCTIONS
BOOL PreCreateDictionary(void) {
#else
BOOL CheckLicense(void) {
#endif
	if(!IsRegistered()) {
		int result = 0;
		result = NSRunAlertPanel(NSLocalizedString(@"Buy iDictionary", nil),
								 NSLocalizedString(@"iDictionary requires you a license to use. You can use the Demo version (dictionary is limited to letters a-d), or buy the full version of iDictionary now. If you already purchased a license, click \"Load License\" to load your license file.", nil),
								 NSLocalizedString(@"Buy License", nil),
								 NSLocalizedString(@"Load License", nil),
								 NSLocalizedString(@"Use Demo", nil));
		
		switch(result) {
			case NSAlertDefaultReturn: //then they want to buy a license
				OPEN_URL(PURCHASE_URL);
				return NO;
			case NSAlertAlternateReturn: //then they want to load a license file
				RunLoadLicensePanel();
				return NO;
			case NSAlertOtherReturn: //then they want to use the demo
				return YES;
				break;
		}
	} else {//then the program is already registered
		return YES;	
	}
	
	 //the executation should never reach this point, but it makes the compiler happy
	return NO;
}

#ifdef HIDDEN_LICENSE_FUNCTIONS
NSDictionary *LicenseDictionaryReference(void) { return nil; } /* fake license dictionary reference to fool hackers */
NSDictionary *DictionaryDataReference(void) {
#else
NSDictionary *LicenseDictionary(void) {
#endif
	extern NSDictionary *_licenseDictionary;
	IsRegistered();
	
	return _licenseDictionary;
}

#ifdef HIDDEN_LICENSE_FUNCTIONS
BOOL _isRegistered() { return NO; } /* fake isRegistered() function to fool people */
BOOL IsValidDictionaryBundle() {
#else
BOOL IsRegistered(void) {
#endif
	static NSMutableString *key = nil;
	static BOOL setKeyError = NO;
	
	NSString *supportFolder, *licenseFile;
	NSURL *licenseURL;
	NSDictionary *licenseDict;
		
	if(!key) {//if the key isn't already created, create the key and register it
		// This string is specially constructed to prevent key replacement
		// *** Begin Public Key ***
		key = [NSMutableString new];
		[key appendString:@"0xEC8131C37A7"];
		[key appendString:@"E"];
		[key appendString:@"E"];
		[key appendString:@"E25B206E242FCCF"];
		[key appendString:@"0548728"];
		[key appendString:@"A"];
		[key appendString:@"A"];
		[key appendString:@"9EE183C6342E4B5A4468B"];
		[key appendString:@"D484A1896A1"];
		[key appendString:@"4"];
		[key appendString:@"4"];
		[key appendString:@"A1579383ED58A2AFE"];
		[key appendString:@"F"];
		[key appendString:@"E"];
		[key appendString:@"E"];
		[key appendString:@"9A6BB3B7AB91D7FCDC5FB66AFF0"];
		[key appendString:@"CB109C1D2"];
		[key appendString:@"B"];
		[key appendString:@"B"];
		[key appendString:@"2AFD1B5E75FDDC38D86"];
		[key appendString:@"B84E31B8DA487A25D4"];
		[key appendString:@"D"];
		[key appendString:@"D"];
		[key appendString:@"856563AE30"];
		[key appendString:@""];
		[key appendString:@"9"];
		[key appendString:@"9"];
		[key appendString:@"66BF9DDFCB64CF23F445AFAAFAE5"];
		[key appendString:@"8531D76AF6BE1254"];
		[key appendString:@"9"];
		[key appendString:@"9"];
		[key appendString:@"11CD19B844E9"];
		[key appendString:@"3231D4F16C99EF17C7"];
		// *** End Public Key ***

		if(APSetKey((CFStringRef) key) == FALSE) {
			NSLog(@"Error setting key");
			setKeyError = YES;
		}
	}

	[_licenseDictionary release];
	_licenseDictionary = nil;
		
	if(setKeyError) {//if their was an error setting the public key
		return NO;	
	}

	if(![[AppSupportController sharedController] isSupportFolderCreated]) {//if the support folder isn't created then the license cant be located there
		return NO;	
	}
	
	if(!(supportFolder = [[AppSupportController sharedController] supportFolder])) {
#if REGISTRATION_DEBUG
		NSLog(@"Error getting support folder");
#endif
		return NO;	
	}
	
	licenseFile = [supportFolder stringByAppendingPathComponent:LICENSE_FILE_NAME];

	if(![[NSFileManager defaultManager] fileExistsAtPath:licenseFile]) {
#if REGISTRATION_DEBUG
		NSLog(@"No license file found!");
#endif
		return NO;
	}
	
	licenseURL = [NSURL fileURLWithPath:licenseFile];
	
	if(!licenseURL) {
#if REGISTRATION_DEBUG
		NSLog(@"Error creating license URL");
#endif
		return NO;
	}
	
	licenseDict = (NSDictionary *) APCreateDictionaryForLicenseFile((CFURLRef) licenseURL);

	if(licenseDict == NULL) {
		return NO;	
	}
	
	extern NSDictionary *_licenseDictionary;
	
	_licenseDictionary = licenseDict; //maybe retain this in the future?
	
	return YES;
}
