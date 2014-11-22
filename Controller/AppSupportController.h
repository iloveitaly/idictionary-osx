//
//  AppSupportController.h
//  DictPod
//
//  Created by Michael Bianco on 2/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MABSupportFolder.h"

//base name for the folders containing the created dictionaries in the support folder
#define DICT_DIR_NAME @"dict"

@class DictRep;

@interface AppSupportController : MABSupportFolder {
	NSArray *_createdDictionaries;
	int _nextDictNumber;
}

+(AppSupportController *) sharedController;

//-----------------------
//	Action Methods
//-----------------------
-(void) checkSupportFolderForDictionaries;
-(void) removeOldDictionaries;

-(DictRep *) existingDictionaryMatching:(NSDictionary *)dict;
-(NSString *) uniqueDictionaryCreationPath;

//-----------------------
//	Notification Methods
//-----------------------
-(void) supportFolderChanged:(NSNotification *)note;
-(void) applicationRegistered:(NSNotification *)note;

//-----------------------
//	Getter & Setter
//-----------------------
-(NSArray *) createdDictionaries;
-(void) setCreatedDictionaries:(NSArray *)ar;
@end
