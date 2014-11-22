//
//  MABDictionary.m
//  DPod
//
//  Created by Michael Bianco on 12/7/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "MABDictionary.h"
#import "MABWord.h"
#import "NSString+Extras.h"

static NSMutableArray *_availableDictionaries = nil;

void *DCSGetActiveDictionaries();

@implementation MABDictionary
//-----------------------
//		Class Methods
//-----------------------
+(NSArray *) availableDictionaries {
	extern NSMutableArray *_availableDictionaries;
	
	//id temp = DCSGetActiveDictionaries();
	//NSLog(@"%@", temp);
	
	if(_availableDictionaries == nil) {
		_availableDictionaries = [[NSMutableArray alloc] initWithCapacity: 2];
		
		DCMDictionaryIterator dictionaries;
		DCMObjectID dictID;
		FSSpec spec;
		FSRef ref;
		NSString *tempPath, *homeSearchPath = [NSHomeDirectory() stringByAppendingString:DICT_SEARCH_PATH];
		UInt8 path[PATH_MAX];
		OSStatus result = noErr;
		
		DCMCreateDictionaryIterator(&dictionaries);
			
		while(result != dcmIterationCompleteErr) {
			result = DCMIterateObject(dictionaries, &dictID);
			
			//get the path of the dictionary
			DCMGetFileFromDictionaryID(dictID, &spec);
			FSpMakeFSRef(&spec, &ref);
			FSRefMakePath(&ref, path, PATH_MAX);
			tempPath = [NSString stringWithUTF8String:(char *) path];

			if([tempPath hasPrefix:DICT_SEARCH_PATH] || [tempPath hasPrefix:homeSearchPath]) {//check to make sure its located in the correct place
				[_availableDictionaries addObject:[[[MABDictionary alloc] initWithPath:tempPath andID:dictID] autorelease]];	
			}
		}
		
		DCMDisposeObjectIterator(dictionaries);
	}
	
	return _availableDictionaries;
}

-(id)initWithPath:(NSString *)path andID:(DCMDictionaryID)dict {
	if(self = [self init]) {
		_dictID = dict;
		_dictPath = [path retain];
		_dictProps = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:@"Contents/Info.plist"]];
		//NSLog(@"%@", _dictProps);
	}
	
	return self;
}

- (id) init {
	if (self = [super init]) {
		_isOpened = NO;
	}
	
	return self;
}

-(void) dealloc {
	[_dictPath release];
	[_dictProps release];
	
	[super dealloc];
}

#ifndef DICTIONARY_GUI
-(NSMutableArray *) matchesForString:(NSString *)searchString {
	return [self _matchesForString:searchString 
							 limit:nil 
						 skipCount:nil
							method:DICT_SEARCH_BEGINNING];
}

//returns nil if more than one definition was found for a word, is no definition
-(MABWord *) definitionForWord:(NSString *)searchString {
	return [[self _matchesForString:searchString
							 limit:nil
						 skipCount:nil
							method:DICT_SEARCH_EQ] objectAtIndex:0];
}

-(NSMutableArray *) _matchesForString:(NSString *)searchString limit:(NSNumber *)limit skipCount:(NSNumber *)skip method:(unsigned int) method {
	if(!_isOpened) {
		[self setIsOpened:YES];
	}
	
	NSString *currWord = nil;
	NSMutableArray *results = nil;
	
	UniChar searchStrBuff[[searchString length]], wordBuff[256];
	UInt32 searchStrSize = [searchString length] * sizeof(UniChar);
	ByteCount wordSize;
	
	DCMFieldTag searchTag = 'dsky';
	DCMFoundRecordIterator recordIterator;
	DCMUniqueID uniqueID;
	OSStatus err;
	
	//clear the buffers
	memset(searchStrBuff, 0, sizeof(searchStrBuff));
	memset(wordBuff, 0, sizeof(wordBuff));

	//convert the string to a UniChar string
	
#ifdef __POWERPC__
	CFStringGetCharacters((CFStringRef) searchString, CFRangeMake(0, [searchString length]), searchStrBuff);
#else
	// on intel macs 1 byte of data must be zero'd in front of the string given to DCMFindRecords
	CFStringGetCharacters((CFStringRef) searchString, CFRangeMake(0, [searchString length]), ((char*)searchStrBuff) + 1);
#endif
	
	//retrieve matches for the search string
	err = DCMFindRecords(_dictRef,		//reference to the dictionary
						 searchTag,		//tag to search through, in this case the 'word' tag
						 searchStrSize,	//size of the keybuffer in bytes
						 searchStrBuff, //UniChar buffer of characters making a string to search for
						 method,		//the find method
						 0,				// count of the items in the next parameter, which is a C-array of DCMFieldTag's
						 NULL,			//array of DCMFieldTags to prefetch
						 0,				//skip count
						 0,				//max record count
						 &recordIterator);
	
	if(err != noErr) {
		NSLog(@"Error retrieving records. Error code %i", err);
		return nil;
	}
		
	//initialize record iterator to the compacity of the records found
	results = [NSMutableArray arrayWithCapacity:DCMCountRecordIterator(recordIterator)];

	while(true) {
		//Iterate a key from found key list. The whole point of this function is to return the unique ID
		err = DCMIterateFoundRecord(recordIterator,
									sizeof(wordBuff),	//size of the keyBuffer. keyBuffer is a UniChar array
									&wordSize,			//on return the size that the wordBuff needs to be to hold the data */
									wordBuff,			//buffer to hold the word
									&uniqueID,			//unique ID on return this ID really isn't that unique though
									NULL /* should be an ASDesc struct, but I'm not prefetching anything */);
		
		if(err != noErr) {
			if(err != dcmIterationCompleteErr) {//if the error isn't normal
				NSLog(@"Error iterating found records! Error code %i", err);
			}
			
			break;
		}

		if(uniqueID != 0) {//then its a second entry for the same word!
			//NSLog(@"Duplicate definition for word %@", CFStringCreateWithCharacters(NULL, wordBuff, sizeof(wordBuff)/sizeof(UniChar)));
			continue;
		}		

		currWord = (NSString *) CFStringCreateWithCharacters(NULL, wordBuff, wordSize/sizeof(UniChar));

		//add the word to the array
		[results addObject:[MABWord wordWithWord:currWord
								   andDictionary:self]];
		
		CFRelease((CFStringRef) currWord);
		memset(wordBuff, 0, sizeof(wordBuff));
	}
	
	DCMDisposeRecordIterator(recordIterator);
	
	return results;
}
#endif

//-----------------------
//		Getter & Setter
//-----------------------

-(BOOL) isOpened {
	return _isOpened;
}

-(void) setIsOpened:(BOOL)b {
	if(b) {
		if(DCMOpenDictionary(_dictID, 0, NULL, &_dictRef) != noErr) {
			NSLog(@"Error opening dictionary");
		}
	} else {
		if(DCMCloseDictionary(_dictRef) != noErr) {
			NSLog(@"Error closing dictionary");
		}
	}
	
	_isOpened = b;
}

-(ItemCount) totalRecords {
	if(!_totalRecords) {
		DCMCountRecord(_dictID, &_totalRecords);
	}
	
	return _totalRecords;
}

-(NSString *) dictionaryName {
	if(!_dictName) {
		_dictName = [[[_dictProps valueForKey:DICT_NAME_KEY] trimWhiteSpace] retain];
	}
	
	return _dictName;
}

-(NSString *) dictionaryPath {
	return _dictPath;
}

-(NSString *) dictionaryCategory {
	return [_dictProps valueForKey:DICT_TYPE_KEY];
}

-(int) dictionaryType {
	if(!_dictType) {
		if([[self dictionaryCategory] isEqualToString:DICT_TYPE_DICT_IDENTIFIER]) {//if we have a dictionary
			_dictType = MABDictionaryType;
		} else if([[self dictionaryCategory] isEqualToString:DICT_TYPE_THESAUR_IDENTIFIER]) {
			_dictType = MABThesaurusType;
		} else {
			NSLog(@"Unknown dictionary type!");
		}
	}
	
	return _dictType;
}

-(DCMDictionaryRef) dictionaryRef {
	return _dictRef;
}
@end
