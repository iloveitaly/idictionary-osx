//http://lists.apple.com/archives/carbon-dev/2005/Oct/msg00102.html

#import "testDict.h"

#import <ApplicationServices/ApplicationServices.h>
#import <AGRegex/AGRegex.h>

#import "MABDictionary.h"

void testDict(void) {
	DCMDictionaryID dictID;
	DCMDictionaryRef dictRef;
	DCMFoundRecordIterator iter;
	DCMFieldTag tags[] = {'dsbd'};
	MABDictionary *dict = [[MABDictionary availableDictionaries] objectAtIndex:0];
	OSStatus result;
	
	CFStringRef ref = CFSTR("hello");
	CFIndex len = CFStringGetLength(ref);
	UniChar *buff[len];
	CFStringGetCharacters(ref, CFRangeMake(0, len), buff);
	
	dictID = (DCMDictionaryID) dict->_dictID;
	dictRef = dict->_dictRef;
	
	result = DCMOpenDictionary(dictID, 0, NULL, &dictRef);
	

	result = DCMFindRecords(dictRef,
							'dsky',
							 len, buff, kDCMFindMethodBeginningMatch, 1, tags, 0, 0,
							 &iter);
	
	switch(result) {
		default:
			NSLog(@"%i", result);
	}
}

void testDict2(void) {
	MABDictionary *dict = [[MABDictionary availableDictionaries] objectAtIndex:0];
	//NSLog(@"%@", [dict definitionForWord:@"a-"]);
	
	DCMDictionaryRef dictionaryRef;
	CFStringRef searchString = CFSTR("poo");
	
	DCMOpenDictionary(dict->_dictID, 0, NULL, &dictionaryRef);

	OSStatus err;
	CFIndex length = CFStringGetLength(searchString);
	char keyBuffer[255] = {0};
	DCMFieldTag keyFieldTag = 'dsky', dataFieldTag = 'dsbd', realWordTag = 'dshw';
	UInt32 keySize = length * sizeof(UniChar);
	DCMUniqueID uniqueID;
	DCMFoundRecordIterator recordIterator;
	Size dataSize;
	CFStringRef dataString, currWord;
	NSMutableString *test = [NSMutableString new];
	
	CFStringGetCharacters(searchString, CFRangeMake(0, length), keyBuffer + 1);
	DCMFieldTag tags[] = {'dshw', 'ds_f'};

	//retrieve matches for the search string
	err = DCMFindRecords(dictionaryRef, 
						 keyFieldTag /* tag to search through, in this case the 'word' tag */,
						 keySize /* size of the keybuffer in bytes */, 
						 keyBuffer /* UniChar buffer of characters making a string to search for */,
						 kDCMFindMethodBeginningMatch, /* the find method */
						 0, /* count of the items in the next parameter, which is a C-array of DCMFieldTag's */
						 NULL,  /* array of DCMFieldTags */
						 0, 0, /* skip count, max record count */
						 &recordIterator);
	
	if(err != noErr) {
		NSLog(@"Error retrieving records %i", err);
		return;
	}
		
	//Iterate found records
	while(true) {
		AEDesc dataDescList;
		UniChar *dataBuffer;
		DescType dataType;
		
		//Iterate a key from found key list. The whole point of this function is to return the unique ID
		err = DCMIterateFoundRecord(recordIterator,
									sizeof(keyBuffer), /* size of the keyBuffer. keyBuffer is an array of UniChar's */
									&keySize, /* on return the size that the keyBuffer needs to be to hold the data */
									keyBuffer,
									&uniqueID, /* unique ID on return, very important, its a unique ID for each entry in the dictionary */
									NULL /* should be an ASDesc struct, but I guess we dont really need it... */);
		
		if(uniqueID != 0) {//then its a second entry for the same word!
			//NSLog(@"Dup %@", CFStringCreateWithCharacters(NULL, keyBuffer, sizeof(keyBuffer)/sizeof(UniChar)));
			continue;
		}
		
		currWord = CFStringCreateWithCharacters(NULL, keyBuffer, sizeof(keyBuffer)/sizeof(UniChar));
		
		/*
		NSLog(@"Str %@", CFStringCreateWithCharacters(NULL, keyBuffer, sizeof(keyBuffer)/sizeof(UniChar)));
		NSLog(@"Key Size %i", keySize);
		NSLog(@"Unique ID %x", uniqueID);
		*/
		
		if (err != noErr) {
			 break;
		}

		//Retrieve data record which belongs to iterated key
		err = DCMGetFieldData(dictionaryRef,
							  keyFieldTag,
							  keySize,
							  keyBuffer,
							  uniqueID, 1,
							  &dataFieldTag, &dataDescList);
		
		//NSLog(@"0x%X", dataDescList.dataHandle);
		//NSLog(@"0x%i", sizeofdataDescList);

		//NSLog(@"Str Get Data %@", CFStringCreateWithCharacters(NULL, keyBuffer, sizeof(keyBuffer)/sizeof(UniChar)));
		if (err != noErr) {
			break;
		}

		//Retrieve XML body text which belongs to retrieved data record
		//get the size of the buffer that needs to be allocated for the XML
		AESizeOfKeyDesc(&dataDescList, /* AEDesc */
						dataFieldTag, /* the XML data key */
						&dataType, /* always 'utxt' represented an a number as far as I can tell. */
						&dataSize /* on return, this represents the size the buffer must be to hold the XML data */);
		
		//allocate a buffer for the XML
		dataBuffer = (UniChar*) malloc(dataSize);

		err = AEGetKeyPtr(&dataDescList,
						  dataFieldTag, /* the XML data key */
						  typeUnicodeText, /* type of text to return, unicode is chosen here */
						  &dataType, /* always 'utxt' represented an a number as far as I can tell. */
						  dataBuffer, /* pointer to the memory buffer to put the unicode into */
						  dataSize,
						  &dataSize /* on return, the actual data that was returned? Not sure, but in any case it shouldn't change its value */);

		dataString = CFStringCreateWithCharacters(NULL, dataBuffer, dataSize/sizeof(UniChar));
		CFShow(dataString);

		//NSLog(@"%@", currWord);
		//NSLog(extractDef(dataString));
		//extractDef(dataString);

		[test appendString:[NSString stringWithFormat:@"%@-%@\n", currWord, extractDef(dataString)]];

		free(dataBuffer);
		CFRelease(dataString);
		CFRelease(currWord);

		//AEDisposeToken(&dataDescList);
		AEDisposeDesc(&dataDescList);
	}

	//[[NSFileHandle fileHandleWithStandardOutput] writeData:[test dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
	
	DCMDisposeRecordIterator(recordIterator);
	DCMCloseDictionary(dictionaryRef);
}

NSString * extractDef(CFStringRef definitionData) {
	AGRegex *extractRegex = [AGRegex regexWithPattern:@"<o:sense>.*<o:def>(.*)</o:def>"], 
			*removeTagsRegex = [AGRegex regexWithPattern:@" ?<[^> ]*>"];
	AGRegexMatch *match;
	NSString *definition = nil;
	
	CFRange startRange, endRange;
	NSRange searchRange;
	CFIndex openPos, closePos;
	
	startRange = CFStringFind(definitionData, CFSTR("<o:SB>"), 0);
	
	if(startRange.location == kCFNotFound) {
		NSLog(@"Error finding '<o:SB>'");
		return nil;
	}
	
	//get the position of opening SB tag
	openPos = startRange.location + 5 /* add the length of the opening tag */;
	
	//get the position of the closing DB tag
	endRange = CFStringFind(definitionData, CFSTR("</o:SB>"), 0);
	closePos = endRange.location;
	
	if(closePos == kCFNotFound) {
		NSLog(@"Error finding '</o:SB>'");
		return nil;
	}

	searchRange = NSMakeRange(openPos, closePos - openPos);
	
	//NSLog(NSStringFromRange(searchRange));
	match = [extractRegex findInString:(NSString *) definitionData range:searchRange];
	if(definition = [match groupAtIndex:1]) {
		definition = [removeTagsRegex replaceWithString:@"" inString:definition];
		return definition;
	} else {//could not extract defintion
		return nil;
	}
}