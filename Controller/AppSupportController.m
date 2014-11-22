//
//  AppSupportController.m
//  DictPod
//
//  Created by Michael Bianco on 2/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AppSupportController.h"
#import "DictionaryCreator.h"
#import "MABDictionary.h"
#import "DictRep.h"
#import "MABSupportFolder.h"
#import "UKKQueue.h"
#import "NSFileManager+Additions.h"
#import "shared.h"

@implementation AppSupportController
+(AppSupportController *) sharedController {//prevents compiler errors
	return (AppSupportController *) [super sharedController];
}

- (id) init {
	if (self = [super init]) {		
		//register for changes in the support folder
		[[UKKQueue sharedFileWatcher] setAlwaysNotify:YES];		//so we recieve all notifications of directory changes
		[[UKKQueue sharedFileWatcher] addPath:_supportFolder];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(supportFolderChanged:)
																   name:UKFileWatcherWriteNotification
																 object:nil];
				
		//check the support folder for dictionaries
		//we don't need to call -[self checkSupportFolderForDictionaries] cause the removeOldDictionaries does it for us
		[self removeOldDictionaries]; //remove old dictionaries
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationRegistered:)
													 name:MABAppRegisteredNotification
												   object:nil];	
	}
	
	return self;
}

-(void) checkSupportFolderForDictionaries {
	 //This function is called when UKKQueue notices that the directory has changes
	 //or when other parts of the program want the created dictionary list updated
	
	NSMutableArray *createdDicts = [NSMutableArray array];	
	_nextDictNumber = 0;

	if([_fileManager pathIsDirectory:_supportFolder]) {//then the support folder is already created
		NSArray *files = [_fileManager directoryContentsAtPath:_supportFolder];
		NSString *tempFile;
		int l = [files count];
		
		while(l--) {
			tempFile = [files objectAtIndex:l];
			if([tempFile hasPrefix:DICT_DIR_NAME]) {
				tempFile = [_supportFolder stringByAppendingPathComponent:tempFile];
				tempFile = [tempFile stringByAppendingPathComponent:DICT_PROP_FILE_NAME];
				//NSLog(@"File exists? %i", [_fileManager fileExistsAtPath:tempFile]);
				
				if([_fileManager fileExistsAtPath:tempFile]) {
					//NSLog(@"Found dir %@", tempFile);
					[createdDicts addObject:[DictRep dictRepWithPropertyPath:tempFile]];
					_nextDictNumber++;
				}
			}
		}
	} else {
		_nextDictNumber = 0;
	}
	
	[self setCreatedDictionaries:createdDicts];
}

-(void) removeOldDictionaries {
	[self checkSupportFolderForDictionaries];
	
	//remove all dictionaries that are:
	// a) built with a older version of iDictionary
	// b) build with a demo version of iDictionary
	DictRep *rep;
	int l = [_createdDictionaries count];
	while(l--) {
		rep = [_createdDictionaries objectAtIndex:l];
		if([[[rep properties] valueForKey:VERSION_KEY] isLessThan:APP_VERSION] || (IsRegistered() && [rep isDemoDictionary])) {
			//NSLog(@"Delete %@", rep);
			if(![_fileManager removeFileAtPath:[rep path]
									   handler:nil]) {
				NSLog(@"Error deleting dictionary");
			}
		}
	}
}

-(DictRep *) existingDictionaryMatching:(NSDictionary *)dict {	
	unsigned int index;
	if((index = [_createdDictionaries indexOfObject:dict]) == NSNotFound)
		return nil;

	return [_createdDictionaries objectAtIndex:index];
}

-(NSString *) uniqueDictionaryCreationPath {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *currentLetterDir, *uniqueDir = [_supportFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%i", DICT_DIR_NAME, _nextDictNumber++]];
	char letter = 'a', maxLetter = IsRegistered()? 'z' : MAX_FREE_VERSION_LETTER_LC;
	
	[self createSupportFolder];
	
	if(![fm createDirectoryAtPath:uniqueDir attributes:nil]) {
		NSLog(@"Error creating unique directory");
	}
	
	if([_fileManager fileExistsAtPath:uniqueDir]) {//make sure the directory doesn't already exist
		for(; letter <= maxLetter; letter++) {//create a directory for each letter
			currentLetterDir = [uniqueDir stringByAppendingFormat:@"/%c", toupper(letter)];
			
			if(![_fileManager createDirectoryAtPath:currentLetterDir attributes:nil]) {
				NSLog(@"Unable to create directory at path %@", currentLetterDir);
			}
		}
	} else {
		return [self uniqueDictionaryCreationPath];
	}

	return uniqueDir;
}

//-----------------------
//	Notification Methods
//-----------------------

-(void) supportFolderChanged:(NSNotification *)note {
	NSLog(@"Changed path %@", [note userInfo]);
	[self checkSupportFolderForDictionaries];
}

-(void) applicationRegistered:(NSNotification *)note {
	[self removeOldDictionaries];
}

//-----------------------
//	Getter & Setter
//-----------------------
-(NSArray *) createdDictionaries {
	//NSLog(@"%@", _createdDictionaries);
	return _createdDictionaries;
}

-(void) setCreatedDictionaries:(NSArray *)ar {
	[ar retain];
	[_createdDictionaries release];
	_createdDictionaries = ar;
}
@end
