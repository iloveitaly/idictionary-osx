#import <AGRegex/AGRegex.h>

#import "MABDictionary.h"
#import "MABWord.h"
#import "shared.h"

static AGRegex *extractRegex = nil, *removeTagsRegex = nil, *removeExtraWhiteSpaceRegex = nil, *findTagRegex = nil, *chatSlangRegex = nil;
BOOL MABWordUseChatSlang = NO;

@implementation MABWord
//-----------------------
//		Class Methods
//-----------------------
+(MABWord *) wordWithWord:(NSString *)word andDictionary:(MABDictionary *)dict {
	return [[[MABWord alloc] initWithWord:word andDictionary:dict] autorelease];
}

//--------------------------------------
//		Initalizers/Superclass overides
//--------------------------------------
-(id) initWithWord:(NSString *)word andDictionary:(MABDictionary *)dict {
	if (self = [self init]) {
		_dictRef = dict;
		_wordKey = [word retain];
	}
	
	return self;	
}

- (id) init {
	if (self = [super init]) {
		_wordSeperator = '/';
		_otherWords = [NSMutableArray new];
		_noDefinition = NO;
	}
	return self;
}


-(void) dealloc {
	[_wordKey release];
	[_word release];
	[_shortDefinition release];
	[_definitionData release];
	[_otherWords release];
	
	[super dealloc];
}

-(NSString *) description {
	return [NSString stringWithFormat:@"%@ : %@", [self word], [self shortDefinition]];	
}

-(BOOL) isEqual:(id) ob {
	if([super isEqual:ob]) {
		return YES;
	} else if([ob isMemberOfClass:[MABWord class]]) {
		//create some temporary variables so i dont have to call the accessors alot
		NSString *tempDef = [self shortDefinition], *compareDef = [ob shortDefinition];
		int tempDefLen, compareDefLen;
		
#if DEBUG_MAB_WORD
		NSString *tempWord = [self word], *compareWord = [ob word];
		
		if(isEmpty(tempDef) && isEmpty(compareDef)) {//this should NEVER occur
			NSLog(@"Both invalid definitions! (%@) & (%@)", tempDef, compareDef);
			return NO;
		}
#endif
		
		if(isEmpty(tempDef) || isEmpty(compareDef)) {
#if DEBUG_MAB_WORD
			NSLog(@"One of the words (%@) has no definition!", isEmpty(tempDef) ? tempWord : compareWord);
#endif
			return NO;
		}

		if((tempDefLen = CFStringGetLength((CFStringRef)tempDef)) != (compareDefLen = CFStringGetLength((CFStringRef)compareDef))) {//check to make sure the lengths are the same first
			return NO;
		}
		
		if(tempDefLen > COMPARE_INDEX) {//make sure the length of the definition is > 3. If tempDef's definition is > 3 then compareDef's definition is
			//compare two characters at different indexes to double check they are the same string
			//this should catch any definitions that just happen to be the same length but do not have the same content
			if([tempDef characterAtIndex:COMPARE_INDEX] != [compareDef characterAtIndex:COMPARE_INDEX] || //compare a character at the relative beggining of the string
			   [tempDef characterAtIndex:tempDefLen - 1] != [compareDef characterAtIndex:tempDefLen - 1]) {//compare a character at the end of the string
				return NO;
			}
		}
#if DEBUG_MAB_WORD
		else {
			NSLog(@"Definitions for %@ (%@) and %@ (%@) are shorter than %i. Lengths are %i, %i", tempWord, tempDef, compareWord, compareDef, COMPARE_INDEX, [tempDef length], [compareDef length]);
		}
#endif
		
		//do a full string comparison just to double check that the strings are equal
		if(![tempDef isEqualToString:compareDef]) {//check to make sure the definitions are indeed equal
			//NSLog(@"Equal lengths, but string not equal");
			return NO;	
		}
		
#if DEBUG_MAB_WORD
		if([tempWord isEqualToString:compareWord]) {
			NSLog(@"Words are equal %@:%@", tempWord, compareWord);
		}
#endif
		
		return YES;
	}
	
	return NO;
}

//-----------------------
//		Action Methods
//-----------------------
-(void) addOtherWord:(MABWord *)w {
	[_otherWords addObject:[w word]];
}

//-----------------------
//		Getter & Setter
//-----------------------
-(void) setWordSeperator:(char) c {
	_wordSeperator = c;	
}

-(NSString *) definitionData {
	if(!_definitionData) {
		_definitionData = [self _getDataForKey:'dsbd'];
		
		if(isEmpty(_definitionData)) {
			_noDefinition = YES;
			_definitionData = nil;
		}
		
		[_definitionData retain];
	}
	
	return _definitionData;
}

-(NSString *) shortDefinition {
	if(!_shortDefinition) {
		extern AGRegex *extractRegex, *removeTagsRegex, *removeExtraWhiteSpaceRegex, *chatSlangRegex;
		extern BOOL MABWordUseChatSlang;
		
		if(!extractRegex) {//if one isn't defined then all of them arent defined
			if([_dictRef dictionaryType] == MABDictionaryType) {
				extractRegex = [[AGRegex alloc] initWithPattern:@"<o:sense>.*?<o:def>(.*?)</o:def>"];
				findTagRegex = [[AGRegex alloc] initWithPattern:@"<o:SB[^>]*>(.*)</o:SB>"];
			} else {
				extractRegex = [[AGRegex alloc] initWithPattern:@"<o:synGrp>(.*?)</o:synGrp>"];
				//no findTagRegex if their is a thesarus
			}
			
			chatSlangRegex = [[AGRegex alloc] initWithPattern:@"\\b(?:a(r)e|yo(u)|(b)e|wh(y))\\b"];
			removeTagsRegex = [[AGRegex alloc] initWithPattern:@" ?<[^> ]*>"];
			removeExtraWhiteSpaceRegex = [[AGRegex alloc] initWithPattern:@"[ ]{2}|^[ ]+|[. ]+$|^ a"];
		}
		
		if(!_noDefinition) {//if definition data is still nil then get the definition
			[self definitionData];
		}
		
		if(isEmpty(_definitionData)) {//if its empty then their is no definition for the word
			//NSLog(@"No definition for word %@", _word);
			return _shortDefinition = nil;
		}
		
		AGRegexMatch *match;
		NSString *definition = nil, *extractedTags;
		
		if(findTagRegex) {
			extractedTags = [[findTagRegex findInString:_definitionData] groupAtIndex:1];
		} else {//then we are looking through a thesaurus
			extractedTags = _definitionData;
		}
		
		if(isEmpty(extractedTags)) {//if we couldn't extract the tags then either AGRegex found a difference in string length, or we really couldn't find the tags
			//NSLog(@"Error finding sb tags, or AGRegex string difference, for word %@", _word);
			return _shortDefinition = nil;
		}
		
		match = [extractRegex findInString:extractedTags];

		if(definition = [match groupAtIndex:1]) {//if there was a successfull match
			definition = [removeTagsRegex replaceWithString:@"" inString:definition];
			definition = [removeExtraWhiteSpaceRegex replaceWithString:@"" inString:definition];
			if(MABWordUseChatSlang) definition = [chatSlangRegex replaceWithString:@"$1" inString:definition];
			_shortDefinition = [definition retain];
			
#if RELEASE_DEF_DATA_EARLY
			//after this point we dont really need the definitionData anymore so release so save on memory space
			[_definitionData release];
			_definitionData = nil;
#endif
		} else {//could not extract defintion
			_shortDefinition = nil;
		}
	}
		
	return _shortDefinition;
}

-(NSString *) word {
	if(!_word) {
		_word = [[self _getDataForKey:'dshw'] retain];
	}
	
	return _word;
}

-(NSString *) allWords {
	//NSLog(@"All words! %@", _otherWords);
	if([_otherWords count] == 0) {//make sure we have some other words
		return [self word];
	} else {		
		NSMutableString *allWords = [NSMutableString string];
		NSString *root = nil, *longestWord = _word, *temp;
		int a, i, l;
		
		l = [_otherWords count];
		while(l--) {
			if(CFStringGetLength((CFStringRef)(temp = (NSString *) CFArrayGetValueAtIndex((CFArrayRef) _otherWords, l))) > CFStringGetLength((CFStringRef) longestWord)) {
				longestWord = temp;
			}
		}
		
		if(longestWord != _word) {//if the longest word isnt the original word then move the original word into _otherWords
			[_otherWords addObject:_word];
			[_word release];
			
			_word = [longestWord retain];
			[_otherWords removeObject:longestWord];
			
		}

		i = [longestWord length] - 2, //the starting index for the root search
		a = 0, l = [_otherWords count];
		
		/*
		 The following algorithm will try to find a root word common in all the words
		 
		 The first part of the algorithm looks from the end of the string to the beggining.
		 "british" being the word in question, the algorithm would (in order) try to find the following routes in the words contained in _otherWords:
		 
			1. britis
			2. briti
			3. brit
		*/

		//search for the root from the end to the beggining
		for(; i > 3 && !root; i--) {//loop down from the length of the word to try to find a common root of all the words. The root must be longer than 3 to make it worthwhile
			root = [longestWord substringToIndex:i];
			for(a = 0; a < l; a++) {//check to make sure the root is found in each word
				if(![[_otherWords objectAtIndex:a] hasPrefix:root]) {//if the root wasn't found in one of the words
					root = nil;
					break;
				}
			}
		}

		if(root) {//if a root was found
			NSString *extractedWord; //the non root part of the word
			
			//NSLog(@"We found a root! %@", root);
			
			//create the beggining of the string
			[allWords appendFormat:@"%@[%@", root, [longestWord substringFromIndex:[longestWord rangeOfString:root].location + [root length]]];

			for(a = 0; a < l; a++) {
				temp = [_otherWords objectAtIndex:a];
				extractedWord = [temp substringFromIndex:[temp rangeOfString:root].location + [root length]];

				if(a + 1 == l) {//then this is the last word, dont put a word seperator
					if([extractedWord length] == 0) {//make sure we actually have an extracted string
						[allWords appendString:@"]"];
					} else {
						[allWords appendFormat:@"%c%@]", _wordSeperator, extractedWord];
					}
				} else {
					if([extractedWord length] == 0) continue;
					
					[allWords appendFormat:@"%c%@", _wordSeperator, extractedWord];
				}				
			}
		} else {//if a root wasn't found, just string all the words together
			[allWords appendFormat:@"%@%c", longestWord, _wordSeperator];
			
			for(a = 0; a < l; a++) {//go through all the words and concatenate them
				if(a + 1 == l) {//then this is the last word, dont put a word seperator
					[allWords appendString:[_otherWords objectAtIndex:a]];
				} else {
					[allWords appendFormat:@"%@%c", [_otherWords objectAtIndex:a], _wordSeperator];
				}
			}
		}

		return allWords;
	}
}

-(NSString *) _getDataForKey:(DCMFieldTag)targetTag {
	UniChar wordBuffer[[_wordKey length]], *dataBuffer;
	UInt32 wordBuffSize = [_wordKey length] * sizeof(UniChar);

	DCMFieldTag retrieveTag = 'dsky';
	AEDesc dataList;
	DescType dataType;
	Size dataBuffSize;
	DCMDictionaryRef ref = [_dictRef dictionaryRef];
	NSString *keyData = nil;
	
	OSStatus err = noErr;

	//get the word into a UniChar buffer
	memset(wordBuffer, 0, sizeof(wordBuffer));
	CFStringGetCharacters((CFStringRef) _wordKey, CFRangeMake(0, [_wordKey length]), wordBuffer);
	
	//Retrieve data record which belongs to iterated key
	err = DCMGetFieldData(ref,
						  retrieveTag,
						  wordBuffSize,		//size/length of the word key
						  wordBuffer,		//buffer holding the word key
						  0,				//this must always be zero. if > 1 then its a duplicate (or alternate) definition of the word 
						  1, &targetTag,	//the data tag acts as an array
						  &dataList);
	
	if(err != noErr) {
		NSLog(@"Error getting data! Error code %i", err);
		return nil;
	}
	
	//Retrieve XML body text which belongs to retrieved data record
	//get the size of the buffer that needs to be allocated for the XML
	AESizeOfKeyDesc(&dataList,		/* AEDesc data structure */
					targetTag,		/* the target  key */
					&dataType,		/* always 'utxt' represented an a number as far as I can tell. */
					&dataBuffSize	/* on return, this represents the size the buffer must be to hold the XML data */);

	//allocate a buffer for the XML
	dataBuffer = (UniChar *) malloc(dataBuffSize);

	err = AEGetKeyPtr(&dataList,		//AEDesc struct
					  targetTag,		//the target data key
					  typeUnicodeText,	//type of text to return, unicode is chosen here. Maybe use UTF8 in the future?
					  &dataType,		//on return represents the data type. Always 'utxt' represented an a uint as far as I can tell
					  dataBuffer,		//pointer to the memory buffer to put the unicode chars into
					  dataBuffSize,
					  &dataBuffSize		/* on return, the actual data that was returned? Not sure, but in any case it shouldn't change its value */);

	if(err != noErr) {
		NSLog(@"Error AEGetKeyPtr");
	}

	keyData = (NSString *) CFStringCreateWithCharacters(NULL, dataBuffer, dataBuffSize/sizeof(UniChar));

	free(dataBuffer);
	AEDisposeDesc(&dataList);

	return [keyData autorelease];
}
@end
