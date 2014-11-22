#import "DictionaryCreator.h"
#import "AppSupportController.h"
#import "MABDictionary.h"
#import "MABWord.h"
#import "interfaceController.h"
#import "RegistrationHandling.h" /* contains the masked license related functions... */
#import "iPodWordFile.h"
#import "DictRep.h"

/* for some #defines */
#import "Preferences.h"
#import "shared.h"

#if DICT_HELPER_RECORD_TIME
#import <time.h>
#endif

//shared creator...
DictionaryCreator *_sharedCreator = nil;

@interface DictionaryCreator (Private)
-(void) processNextLetter;
-(void) createTaskForLetter:(char) c;
-(void) copyDictionaryFiles;
-(void) writeStateFile;
-(void) creationComplete;
@end

@implementation DictionaryCreator
+(DictionaryCreator *) sharedCreator {
	extern DictionaryCreator *_sharedCreator;
	return _sharedCreator;
}

//----------------------------------------------
//		Superclass Overides
//----------------------------------------------

- (id) init {
	if ((self = [super init]) != nil) {
		extern DictionaryCreator *_sharedCreator;
		_sharedCreator = self;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(helperClosed:)
													 name:@"NSTaskDidTerminateNotification"
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationRegistered:)
													 name:MABAppRegisteredNotification
												   object:nil];		
	}
	
	return self;
}

-(void) awakeFromNib {
	[oMinWordLen setIntValue:DEFAULT_MIN_WORD_LEN];
	[oMaxWordLen setIntValue:DEFAULT_MAX_WORD_LEN];
	
	[oProgress setUsesThreadedAnimation:YES];
	[oProgress setMaxValue:PROGRESS_STEPS];
	[oStatus setStringValue:@""];
}

//----------------------------------------------
//				Action Methods
//----------------------------------------------

-(IBAction) stopCreation:(id)sender {
	if(_isCreatingDictionary) {//double check that we are actually creating a dictionary
		//kill the task that is currently running 
		[_currTask terminate];
		[_currTask release];
		_currTask = nil;
		
		[self writeStateFile]; //write the state file
		[self setIsCreatingDictionary:NO];
				
		[NSApp endSheet:oProgressSheet returnCode:NSCancelButton];
		[oProgressSheet orderOut:sender];
		
		//let the controller know we inserted a pause file...
		[[AppSupportController sharedController] checkSupportFolderForDictionaries];
	} else {
		NSLog(@"Cant stop creation, not creating dictionary!");
	}
}

-(IBAction) closeSheet:(id)sender {	
	//get rid of the sheet
	[NSApp endSheet:oProgressSheet returnCode:NSOKButton];
	[oProgressSheet orderOut:nil];
}

#pragma mark Main Creator Function
-(IBAction) createDictionary:(id)sender {
	if(!CheckLicense()) {
		return;	
	}
	
	if(![oMainWindow makeFirstResponder:oMainWindow]) {//validate all the text field data
		NSBeep();
		return;
	}
	
	if(([oMaxWordLen intValue] != 0 && [oMinWordLen intValue] >= [oMaxWordLen intValue]) || [oMinWordLen intValue] == 0) {//check word length ranges
		NSRunInformationalAlertPanel(
									 NSLocalizedString(@"Bad Min & Max Word Lengths", nil),
									 NSLocalizedString(@"Your min word length must be less than your max word length", nil),
									 NSLocalizedString(@"Ok", nil), nil, nil);
		return;
	}
	
	if(isEmpty([oDictionariesController selectedObjects])) {//if the user didn't select a dictionary to use
		//show an alert panel
		NSRunAlertPanel(
						NSLocalizedString(@"Error Creating Dictionary", @"Error Creating Dictionary"),
						NSLocalizedString(@"You must select one dictionary to use", @"You must select one dictionary to use"),
						nil, nil, nil);
		return;
	}

	//get the index of the dictionary we will be using, and get a reference of the MABDictionary we will use
	_dict = [[[oDictionariesController selectedObjects] objectAtIndex:0] valueForKey:DICT_KEY];
	_dictIndex = [[MABDictionary availableDictionaries] indexOfObject:_dict];
	
	//create the properties dictionary that will be used to check for previously created dictionaries
	DictRep *createdDictionary;
	NSDictionary *propDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[oPhrase objectValue], [oMinWordLen objectValue], [oMaxWordLen objectValue], 
																						   [oHyphen objectValue], [oNoun objectValue], [oContractions objectValue], 
																						   [oAbbrev objectValue], [oDefinitionVariations objectValue], [_dict dictionaryName], 
																						   [oChatSlang objectValue], [NSNumber numberWithInt:_fileType], [oPrefix stringValue],
																						   APP_VERSION, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],
																						   [NSNumber numberWithBool:!IsRegistered()], nil]
														 forKeys:[NSArray arrayWithObjects:PHRASE_KEY, MIN_WORD_LEN_KEY, MAX_WORD_LEN_KEY, 
																						   HYPEN_WORD_KEY, NOUNS_KEY, APOSTROPHES_KEY, 
																						   ABBREV_KEY, DEF_VARIATIONS_KEY, DICT_USED_KEY, 
																						   CHAT_SLANG_KEY, FILE_TYPE_KEY, FILE_PREFIX_KEY,
																						   VERSION_KEY, APP_NAME_KEY, DEMO_VERSION_KEY, nil]];
	
	//set the options dictionary. All the check-boxes's object value is a NSNumber (its really a CFBoolean)
	[self setOptions:propDict];
	
	if(isEmpty([oIPodController selectedObjects])) {//check to make sure we selected an ipod
		if(NSRunInformationalAlertPanel(
										NSLocalizedString(@"No iPod Selected", nil),
										NSLocalizedString(@"You have not selected an iPod copy the dictionary to. If you do not select an iPod the dictionary will still be created for future use.", nil),
										NSLocalizedString(@"Select an iPod", nil), NSLocalizedString(@"Continue Anyway", nil), nil) == NSOKButton) {
			NSLog(@"Select an ipod");
			return;
		} else {//if the user doesn't want to select another ipod then their is no copy path
			[self setCopyPath:nil];
		}
	} else {//then an ipod was selected, so set the copy path
		NSString *podPath = [[[oIPodController selectedObjects] objectAtIndex:0] valueForKey:IPOD_PATH_KEY];
		NSString *notesPath;
		
		if(_fileType == MABPlainTextFile) {
			notesPath = [podPath stringByAppendingPathComponent:IPOD_NOTES_FOLDER];
		} else {
			notesPath = [podPath stringByAppendingPathComponent:IPOD_CONTACT_FOLDER];
		}
		
		[self setCopyPath:[notesPath stringByAppendingPathComponent:[_dict dictionaryName]]];
		
		NSFileManager *fm = [NSFileManager defaultManager];
		if(![fm fileExistsAtPath:notesPath]) {
			NSLog(@"Notes folder on the ipod doesn't exist! %@", _copyTargetPath);
		}
	}

	if((createdDictionary = [[AppSupportController sharedController] existingDictionaryMatching:propDict]) && [createdDictionary isIncomplete]) {//then was partially created
		NSLog(@"Dictionary already created at path %@. Pause state %c", [createdDictionary path], [createdDictionary pausedState]);
		[self setTargetPath:[createdDictionary path]];
		[self setIsCreatingDictionary:YES]; //since we've already created part of it earlier
		
		_currLetter = [createdDictionary pausedState]; //set the current letter to the letter at which the creation stopped before
		
		//set the progess bar to correctly represent the progress we have had so far
		[oProgress setDoubleValue:3.0 * (_currLetter - 'A')];
		
		//clear the directory that we will be processing next
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *dirToProcess = [_targetPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%c", _currLetter]];
		
		if(![fm removeFileAtPath:dirToProcess
						handler:self]) {
			NSLog(@"Error removing directory at path %@", dirToProcess);
		}
		
		if(![fm createDirectoryAtPath:dirToProcess
						   attributes:nil]) {
			NSLog(@"Error creating directory at path %@", dirToProcess);
		}
		
		//decrement the _currLetter because it will be incremented very soon
		_currLetter--;
	} else if(createdDictionary && ![createdDictionary isIncomplete]) {//the dictionary is already totally completed
		//NSLog(@"Created dictionary %@", [createdDictionary properties]);
		if(isEmpty([oIPodController selectedObjects]) && !_copyTargetPath) {//if the dictionary is already created and we dont have a destination path
			NSRunAlertPanel(
							NSLocalizedString(@"Dictionary Already Created", nil),
							NSLocalizedString(@"A dictionary with these settings has previously been created. Choose an iPod to copy the dictionary onto.", nil),
							nil, nil, nil);
			return;
		}

		[self setTargetPath:[createdDictionary path]];
		[self setIsCreatingDictionary:NO];
		[oProgress setDoubleValue:PROGRESS_STEPS];
		
		//begin the progress sheet
		[NSApp beginSheet:oProgressSheet
		   modalForWindow:oMainWindow
			modalDelegate:self
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
		
		[oStatus setStringValue:@"a "];
				
		[self copyDictionaryFiles];
		return; //we dont want to create the dictionary at all
	} else {//then we are creating a new dictionary
		[self setTargetPath:[[AppSupportController sharedController] uniqueDictionaryCreationPath]];
		NSLog(@"Creating new dictionary at path %@", [self targetPath]);
		
		//create the directory structure, then start the dictionary creation process
		_currLetter = 'A';
		[self setIsCreatingDictionary:NO];
		
		//write the properties file to the path
		[self setPropertiesPath:[_targetPath stringByAppendingPathComponent:DICT_PROP_FILE_NAME]];
		[propDict writeToFile:_propertiesPath
				   atomically:YES];
	}

	//begin the progress sheet
	[NSApp beginSheet:oProgressSheet
	   modalForWindow:oMainWindow
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
	
	[self processNextLetter];
}

#define setCheckState(k, n) [n setState:[[[rep properties] valueForKey:k] boolValue]]

-(void) selectDictionary:(DictRep *) rep {
	//NSLog(@"Select dictionary %@", [rep path]);
	
	//synch UI with the properties in this dictrep
	setCheckState(CHAT_SLANG_KEY, oChatSlang);
	setCheckState(PHRASE_KEY, oPhrase);
	setCheckState(ABBREV_KEY, oAbbrev);
	setCheckState(HYPEN_WORD_KEY, oHyphen);
	setCheckState(NOUNS_KEY, oNoun);
	setCheckState(APOSTROPHES_KEY, oContractions);
	setCheckState(DEF_VARIATIONS_KEY, oDefinitionVariations);
	
	[oPrefix setStringValue:[[rep properties] valueForKey:FILE_PREFIX_KEY]];
	[self setFileType:[[[rep properties] valueForKey:FILE_TYPE_KEY] intValue]];
	
	//select the dictionary used in this dictRep
	//we use DICT_USED_KEY since -[DictRep name] doesn't really give the actual name of the dictionary
	//it gives us the name used in the CreatedDictCell
	NSArray *dicts = [oDictionariesController arrangedObjects];
	int l = [dicts count];
	while(l--) {
		if([[[dicts objectAtIndex:l] valueForKey:TITLE_KEY] isEqualToString:[[rep properties] valueForKey:DICT_USED_KEY]]) {
			[oDictionariesController setSelectionIndex:l];
		}
	}
}

//----------------------------------------------
//	Notification Methods For NSTask Stuff
//----------------------------------------------
-(void) helperClosed:(NSNotification *) note {
	if([_currTask terminationStatus]) {
		NSLog(@"Helper application closed with exit code %i", [_currTask terminationStatus]);
		return;
	}
	
#if DICT_HELPER_RECORD_TIME
	_totalTime += time(NULL) - _startTime;
	NSLog(@"Dictionary files for letter %c took %i seconds to create", _currLetter, time(NULL) - _startTime);
#endif
	
	if(_isCreatingDictionary) { 
		[self processNextLetter];
	} else {//_isCreatingDictionary should only be false when stopCreation: is called
		[_currTask release];
		_currTask = nil;
	}
}

-(void) helperData:(NSNotification *)note {
	NSData *readData = [[note userInfo] valueForKey:FILE_HANDLE_DATA_KEY];
#if DICT_CNTRL_DEBUG
	NSLog(@"Got Data: %s", [[[note userInfo] valueForKey:FILE_HANDLE_DATA_KEY] bytes]);
#endif
	
	if([readData length] > 0) {
		[oStatus setStringValue:[NSString stringWithCString:[readData bytes] length:[readData length]]];
		[oProgress incrementBy:PROGRESS_INCR];
		[_currReadHandle readInBackgroundAndNotify]; //only look for more data if we actually got valid data
	} else {
#if DICT_CNTRL_DEBUG
		NSLog(@"Data from child process is 0 length. Most likely EOF");
#endif
	}
}

//----------------------------------------------
//	Notification Methods For UI Stuff
//----------------------------------------------
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
	//NSLog(@"Sheet ended");
	
	//clear the paths and such
	[self setTargetPath:nil];
	[self setCopyPath:nil];
	[self setPropertiesPath:nil];
	
	//reset the sheet and its UI elements
	[oProgress setDoubleValue:0.0];
	[oProgress stopAnimation:self];
	[oProgress setIndeterminate:NO];
	[oProgress setMaxValue:PROGRESS_STEPS];
	
	[oStatus setStringValue:@""];
	
	//reset the sheet
	[oSheetButton bind:@"enabled"
			  toObject:self
		   withKeyPath:@"isCreatingDictionary"
			   options:nil];
	[oSheetButton setTitle:NSLocalizedString(@"Stop Dictionary Creation", nil)];
	[oProgressSheet setDefaultButtonCell:nil];
}

//----------------------------------------------
//	Notification Methods For UI Stuff
//----------------------------------------------
-(BOOL) fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo {
	NSLog(@"File manager error! %@", errorInfo);
	return NO;
}

-(void) fileManager:(NSFileManager *)manager willProcessPath:(NSString *)path {
	//NSLog(@"Copying file at path %@", path);
}

//----------------------------------------------
//	Other Notifications
//----------------------------------------------
-(void) applicationRegistered:(NSNotification *)note {
	[oProgress setMaxValue:PROGRESS_STEPS];
}

//-----------------------
//		Getter & Setters
//-----------------------

#pragma mark Getter & Setter

-(BOOL) isCreatingDictionary {
	return _isCreatingDictionary;
}

-(void) setIsCreatingDictionary:(BOOL) b {
	_isCreatingDictionary = b;
}

-(NSDictionary *) options {
	return _options;
}

-(void) setOptions:(NSDictionary *)options {
	[options retain];
	[_options release];
	_options = options;
}

-(NSString *) targetPath {
	return _targetPath;
}

-(void) setTargetPath:(NSString *)path {
	[path retain];
	[_targetPath release];
	_targetPath = path;
}

-(NSString *) copyPath {
	return _copyTargetPath;
}

-(void) setCopyPath:(NSString *)path {
	[path retain];
	[_copyTargetPath release];
	_copyTargetPath = path;
}

-(NSString *) propertiesPath {
	return _propertiesPath;	
}

-(void) setPropertiesPath:(NSString *)path {
	[path retain];
	[_propertiesPath release];
	_propertiesPath = path;
}

- (MABFileType) fileType {
	return _fileType;
}

- (void) setFileType:(MABFileType)fileType {
	//if we are not contact files, no prefix
	if(fileType == MABPlainTextFile) [oPrefix setStringValue:@""];
	
	_fileType = fileType;
}

@end

//==================================
//
//			Private Methods
//
//==================================

@implementation DictionaryCreator (Private)
-(void) processNextLetter {
	if(_isCreatingDictionary) {//we dont want to skip the first letter 'A'
		_currLetter++;
	}
	
	if(_currLetter > (IsRegistered() ? 'Z' : MAX_FREE_VERSION_LETTER_UC)) {//then we are done creating the dictionary
		
#if DICT_HELPER_RECORD_TIME
		NSLog(@"Dictionary creation took %i seconds (%.2f minutes)", _totalTime, _totalTime/(float) 60);
		NSLog(@"The dictionary file creation for each letter took (on average) about %i seconds", _totalTime/LETTER_COUNT);
		NSLog(@"The dictionary has %i records. Each entry (word) in the dictionary took about %.6f seconds to process", 
			  [[[MABDictionary availableDictionaries] objectAtIndex:_dictIndex] totalRecords], 
			  _totalTime/(float)[[[MABDictionary availableDictionaries] objectAtIndex:_dictIndex] totalRecords]);
		_totalTime = 0; //reset the time counter
#endif
		[self setIsCreatingDictionary:NO];
		
		[_currTask release];
		_currTask = nil;
		
		//remove the state file, if we have one
		NSString *stateFile = [_targetPath stringByAppendingPathComponent:DICT_PAUSE_FILE_NAME];
		NSFileManager *fm = [NSFileManager defaultManager];
		
		if([fm fileExistsAtPath:stateFile]) {
			if(![fm removeFileAtPath:stateFile
							 handler:self]) {
				NSLog(@"Error removing state file after dictionary creation");
			}
		}
		
		//copy all the files to the iPod
		if(_copyTargetPath) {
			[self copyDictionaryFiles];
		} else {
			[oStatus setStringValue:NSLocalizedString(@"Dictionary successfully created", nil)];
			[self creationComplete];
		}
		
		return;
	}
	
	[self setIsCreatingDictionary:YES];
	[self createTaskForLetter:_currLetter];
	[self writeStateFile];
}

-(void) createTaskForLetter:(char) c {
	//kill the previous task and stop observing the file handle associated with it
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"NSFileHandleReadCompletionNotification"
												  object:_currReadHandle];
	[_currTask release];
	
	//create a new task
	_currTask = [NSTask new];
	
	//we are going to need to access the stdout & stdin for interprocess communication so make a NSPipe for each
	[_currTask setStandardOutput:[NSPipe pipe]];
	[_currTask setStandardInput:[NSPipe pipe]];
	
	[_currTask setArguments:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%c", _currLetter], _targetPath, nil]];
	[_currTask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"helper" ofType:@""]];
	
	[_currTask launch];
	
#if DICT_HELPER_RECORD_TIME
	_startTime = time(NULL);
#endif
	
	//send the slow creation pref
	BOOL slowCreation = PREF_KEY_BOOL(SLOW_DICTIONARY_CREATION);
	write([[[_currTask standardInput] fileHandleForWriting] fileDescriptor], &slowCreation, sizeof(BOOL));
	
	//send the index of the dictionary
	write([[[_currTask standardInput] fileHandleForWriting] fileDescriptor], &_dictIndex, sizeof(int));
	
	//send the dictionary object through stdin
	[[[_currTask standardInput] fileHandleForWriting] writeData:[NSKeyedArchiver archivedDataWithRootObject:_options]];
	[[[_currTask standardInput] fileHandleForWriting] closeFile];
	
	//wait for data to appear on stdout
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(helperData:)
												 name:@"NSFileHandleReadCompletionNotification"
											   object:_currReadHandle = [[_currTask standardOutput] fileHandleForReading]];
	
	[_currReadHandle readInBackgroundAndNotify];
	//NSLog(@"%@", [[_currTask standardOutput] fileHandleForReading]);
}

-(void) copyDictionaryFiles {
	NSLog(@"Copying dictionary files...");
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL fileExists = NO;
	
	
	[oStatus setStringValue:NSLocalizedString(@"Copying files to iPod...", nil)];
	[oProgress setIndeterminate:YES];
	[oProgress startAnimation:self];
	
	if([fm fileExistsAtPath:_copyTargetPath]) {
		if(NSRunAlertPanel(
						   NSLocalizedString(@"Dictionary Already Exists", nil),
						   [NSString stringWithFormat:NSLocalizedString(@"%@ is already present on your iPod, do you want to overwrite it?", nil), [_dict dictionaryName]],
						   NSLocalizedString(@"Yes", nil), 
						   NSLocalizedString(@"No", nil), nil) == NSOKButton) {//if the user does want to delete the files on the iPod
			if(![fm removeFileAtPath:_copyTargetPath
							 handler:self]) {
				NSLog(@"Error removing files at path %@", _copyTargetPath);
			}
		} else {//if the user doesn't want to delete the files on the iPod
			[oStatus setStringValue:NSLocalizedString(@"Unable to copy dictionary files to iPod", nil)];
			[oProgress stopAnimation:self];
			fileExists = YES;
		}
	}
	
	//allows the oStatus string to be drawn... otherwise copyPath:... would take up all the thread CPU power
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
	
	//if the files dont already exist on the iPod, or if the user wants to overwrite the existing files
	if(!fileExists) {
		//count how many dictionary files their are...
		//we really dont need to do this if we are using vcards
		int fileCount = 0;
		NSString *file;
		NSDirectoryEnumerator *dirEnum = [fm enumeratorAtPath:_targetPath];
		
		//count the amount of files in the dictionary
		while((file = [dirEnum nextObject]) != nil) {
			if([file characterAtIndex:0] != '.' && [file length] > 1) {//exclude directories, in the future maybe use isDir from cssoptimizer
				//NSLog(@"File %@", file);
				fileCount++;
			}
		}
		
		if(fileCount > MAX_IPOD_FILES && _fileType == MABPlainTextFile) {//if we have too many files and we are using iPod notes, not contacts
			NSRunInformationalAlertPanel(
										 NSLocalizedString(@"Too Many Files!", nil),
										 [NSString stringWithFormat:NSLocalizedString(@"The iPod can hold a maximum of 1000 files, the dictionary that was just created has %i files. You will not be able to access part of the dictionary. Try using different filter options to reduce the number of files.", nil), fileCount],
										 nil, nil, nil);
		}
		
		//copy files to the ipod
		[fm copyPath:_targetPath
			  toPath:_copyTargetPath
			 handler:self];
		
		//remove the property file on the ipod
		NSString *propFile = [_copyTargetPath stringByAppendingPathComponent:DICT_PROP_FILE_NAME];
		if([fm fileExistsAtPath:propFile]) {
			if(![fm removeFileAtPath:propFile
							 handler:self]) {
				NSLog(@"Error removing prop file on copy!");	
			}
		} else {
			NSLog(@"No prop file found on copying!");	
		}
		
		//if we are using the free version add a "Buy Now" file to the iPod
		if(!IsRegistered()) {
			NSString *buyNowFile;
			
			if(_fileType == MABPlainTextFile) {
				buyNowFile = [[NSBundle mainBundle] pathForResource:@"buynow" ofType:@"txt"];
			} else {//vcard
				buyNowFile = [[NSBundle mainBundle] pathForResource:@"buynow" ofType:@"vcf"];
			}
			
			if(buyNowFile) {
				if(![fm copyPath:buyNowFile
						  toPath:[_copyTargetPath stringByAppendingPathComponent:DICT_BUY_NOW_NAME]
						 handler:self]) {
					NSLog(@"Error copying buy now file!");
				}
			} else {
				NSLog(@"Error getting buynow file!");
			}
		}
		
		[oProgress stopAnimation:self];
		[oStatus setStringValue:NSLocalizedString(@"Dictionary files successfully copied to iPod!", nil)];
	}
	
	[self creationComplete];
}

-(void) writeStateFile {
	//write the paused state
	if(![[NSString stringWithCString:&_currLetter length:1] writeToFile:[_targetPath stringByAppendingPathComponent:DICT_PAUSE_FILE_NAME]
															 atomically:NO
															   encoding:NSASCIIStringEncoding
																  error:nil]) {
		NSLog(@"Error writing state file");
	}	
}

-(void) creationComplete {	
	//set the button properties
	[oProgressSheet setDefaultButtonCell:[oSheetButton cell]];
	[oSheetButton unbind:@"enabled"];
	[oSheetButton setEnabled:YES];
	[oSheetButton setTitle:NSLocalizedString(@"Ok", nil)];
	[oSheetButton setAction:@selector(closeSheet:)];
	
	//refresh the dictionary list
	[[AppSupportController sharedController] checkSupportFolderForDictionaries];
}
@end
