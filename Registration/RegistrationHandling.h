/*
 *  RegistrationHandling.h
 *  DictPod
 *
 *  Created by Michael Bianco on 3/15/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import "shared.h"

#define REGISTRATION_DEBUG 0

//notification that the app has been registered
#define MABAppRegisteredNotification @"applicationRegistered"

int RunInvalidLicenseAlert(void);
int RunSuccessfulLicenseAlert(void);
int RunBuyNowAlert(void);
void RunLoadLicensePanel(void);

#ifdef HIDDEN_LICENSE_FUNCTIONS
/* create false names for the license related functions and map the old names to the new names */

#define CheckLicense() PreCreateDictionary()
BOOL PreCreateDictionary(void);

#define IsRegistered() IsValidDictionaryBundle()
BOOL IsValidDictionaryBundle();

#define LicenseDictionary() DictionaryDataReference()
NSDictionary *DictionaryDataReference(void);

#else /* use regular names */
BOOL CheckLicense(void);
BOOL IsRegistered();
NSDictionary *LicenseDictionary(void);
#endif
