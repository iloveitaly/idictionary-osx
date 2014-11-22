//
//  iPodWordFile.m
//  DPod
//
//  Created by Michael Bianco on 12/9/05.
//  Copyright 2005 Prosit Software. All rights reserved.
//

#import "iPodWordFile.h"
#import "MABWord.h"
#import "shared.h"

#import <ctype.h>

@implementation iPodWordFile

//------------------------------
//		Initializers
//-----------------------------
-(id) initWithWord:(MABWord *)w {
	if(self = [self init]) {
		_words = [[NSMutableArray alloc] initWithCapacity:AVG_ARRAY_SIZE];
		[self addWord:w];
	}
	
	return self;
}

-(id) initWithWords:(NSArray *)a {
	if(self = [self init]) {
		[self setWords:a];
	}
	
	return self;
}

- (id) init {
	if (self = [super init]) {
		_phrases = NO;
		_hyphenatedWords = NO;
		_nouns = NO;
		_abbreviations = NO;
		_apostrophes = NO;
		_slashes = NO;
		_definitionVariations = NO;
		_fileType = MABPlainTextFile;
		_vcardPageCount = 2; // not zero based counting
		_minWordLen = DEFAULT_MIN_WORD_LEN;
		_maxWordLen = DEFAULT_MAX_WORD_LEN;
	}
	
	return self;
}

-(void) dealloc {
	[_prefix release];
	[_options release];
	[_fromWord release];
	[_toWord release];
	[_words release];
	
	[super dealloc];
}

//------------------------------
//		Action Methods
//-----------------------------
-(void) addWord:(MABWord *)w {
	[_words addObject:w];
}

-(void) sortWords {
	//initalize variables to be used in the main processing loop
	NSAutoreleasePool *pool;
	int a = 0, l = [_words count];
	MABWord *tempWord;			//temporary variable to store the object retrieved from the array
	BOOL discard = NO;			//BOOL determining if we should discard the current word we are looking at or not
	unichar tempChar;
	
	NSMutableArray *sortedWords[MAX_DEFINITION_LENGTH];		//hash table to store the arrays in sortedWords
	NSMutableArray *arrayStack[ARRAY_RELEASE_STACK_LENGTH];	//stack to hold all the arrays in sortedWords
	int arrayPointer = 0;									//pointer to the current position in the array stack
	
	//clear the arrays
	memset(sortedWords, nil, MAX_DEFINITION_LENGTH);
	memset(arrayStack, nil, ARRAY_RELEASE_STACK_LENGTH);
	
	for(; a < l; a++, discard = NO, [pool release]) {
		pool = [NSAutoreleasePool new]; //create a new autorelease pool for each interation
		
		//check all the restrictions and remove the word if it doesn't meet all the restrictions
		tempWord = (MABWord *) CFArrayGetValueAtIndex((CFArrayRef)_words, a);
		if(CFStringGetLength((CFStringRef) [tempWord word]) < _minWordLen) {//check minimum length
#if DEBUG_IPOD_WORD_FILE
			NSLog(@"Discarding word %@, does not meet minimum length", [tempWord word]);
#endif
			discard = YES;
		} else if(_maxWordLen != 0 && CFStringGetLength((CFStringRef) [tempWord word]) > _maxWordLen) {//check the maximum length
#if DEBUG_IPOD_WORD_FILE
			NSLog(@"Discarding word %@, exceeds maximum word length", [tempWord word]);
#endif
			discard = YES;
		} else if(!_phrases && [[tempWord word] rangeOfString:@" "].location != NSNotFound) {//check for spaces
#if DEBUG_IPOD_WORD_FILE
			NSLog(@"Discarding word %@, has a space in the word", [tempWord word]);
#endif
			discard = YES;
		} else if(!_hyphenatedWords && [[tempWord word] rangeOfString:@"-"].location != NSNotFound) {//check for hyphens
#if DEBUG_IPOD_WORD_FILE
			NSLog(@"Discarding word %@, has a hyphen in the word", [tempWord word]);
#endif
			discard = YES;
		} else if(!_abbreviations && [[tempWord word] rangeOfString:@"."].location != NSNotFound) {//check for words with periods. Check for a full uppercase string in the future
#if DEBUG_IPOD_WORD_FILE
			NSLog(@"Discarding word %@, has a period", [tempWord word]);
#endif
			discard = YES;
		} else if(!_apostrophes && [[tempWord word] rangeOfString:@"'"].location != NSNotFound) {//check for apostrophes
#if DEBUG_IPOD_WORD_FILE
			NSLog(@"Discarding word %@, apostrophe found", [tempWord word]);
#endif
			discard = YES;
		} else if(!_slashes && [[tempWord word] rangeOfString:@"/"].location != NSNotFound) {//check for slashes
#if DEBUG_IPOD_WORD_FILE
			NSLog(@"Discarding word %@, slash in word", [tempWord word]);
#endif
			discard = YES;
		} else if(!_nouns && isascii(tempChar = [[tempWord word] characterAtIndex:0]) && isupper(tempChar)) {//check for captialized words
#if DEBUG_IPOD_WORD_FILE
			NSLog(@"Discarding word %@, is proper noun", [tempWord word]);
#endif
			discard = YES;
		} else if(isEmpty([tempWord shortDefinition])) {
#if DEBUG_IPOD_WORD_FILE
			NSLog(@"Discarding word %@, no definition associated with the word!", [tempWord word]);
#endif
			discard = YES;
		} else {//make sure we want to check for dupes
			int defLength, foundIndex;
			defLength = CFStringGetLength((CFStringRef) [tempWord shortDefinition]);
				
			if(!sortedWords[defLength]) {//if their isn't a array created for this length
				sortedWords[defLength] = arrayStack[arrayPointer++] = [[NSMutableArray alloc] initWithObjects:tempWord, nil];
			} else {
				foundIndex = [sortedWords[defLength] indexOfObject:tempWord];
				if(foundIndex != NSNotFound) {
					[(MABWord *) CFArrayGetValueAtIndex((CFArrayRef) sortedWords[defLength], foundIndex) addOtherWord:tempWord];
					discard = YES;
				} else {
					CFArrayAppendValue((CFMutableArrayRef) sortedWords[defLength], tempWord);
				}
			}
		}
		
		if(discard) {//check if we need to discard the current word
#if DEBUG_IPOD_WORD_FILE >= 2
			NSLog(@"Discarding word at index %i, a");
#endif			
			//remove the object and decrement the position counter and length counter
			CFArrayRemoveValueAtIndex((CFMutableArrayRef)_words, a);
			l--;
			a--;			
		}
	}
	
	//NSLog(@"Length of array stack %i", arrayPointer);
	while(arrayPointer--) {//release all the temporary arrays
		[arrayStack[arrayPointer] release];
	}
}

- (void) writeFileToPath:(NSString *)path {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableString *data; //plain text file only
	NSMutableArray *pages; //contact files only
	
	if(_fileType == MABPlainTextFile) {
		data = [[NSMutableString alloc] initWithCapacity:MAX_IPOD_FILE_LEN];
	} else {
		pages = [[NSMutableArray alloc] initWithCapacity:_vcardPageCount];
		
		//fill the array with NSMutableString instances
		int l = _vcardPageCount;
		while(l--) {
			[pages addObject:[NSMutableString stringWithCapacity:MAX_IPOD_CONTACT_FIELD_LEN * 2]];
		}

		//set the data reference
		data = [pages objectAtIndex:0];
	}
	
	//initalize variables to be used in the main processing loop
	NSString *tempStr, *lastWord = nil;
	MABWord *tempWord;
	iPodWordFile *branch = nil;	//branch file, if the data exceeds 4kb another file will be created
	int l = [_words count];
	
	[self setFromWord:[[_words objectAtIndex:0] word]];

	while(l) {//loop while their are words left to process
		//create the string to be appended to 'file string'
		if(_definitionVariations) {
			if(_fileType == MABPlainTextFile) {
				tempWord = [_words objectAtIndex:0];
				tempStr = [[NSString alloc] initWithFormat:@"%@-%@\n\n", [tempWord allWords], [tempWord shortDefinition]];
			} else {//vcard
				tempWord = [_words objectAtIndex:0];
				tempStr = [[NSString alloc] initWithFormat:@"%@-%@\\n\\n", [tempWord allWords], [tempWord shortDefinition]];
			}
		} else {
			if(_fileType == MABPlainTextFile) {
				tempWord = [_words objectAtIndex:0];
				tempStr = [[NSString alloc] initWithFormat:@"%@-%@\n\n", [tempWord word], [tempWord shortDefinition]];
			} else {//vcard
				tempWord = [_words objectAtIndex:0];
				tempStr = [[NSString alloc] initWithFormat:@"%@-%@\\n\\n", [tempWord word], [tempWord shortDefinition]];
			}
		}
		
		//branch off another iPodWordFile if we exceed the max file size
		if([tempStr length] + [data length] > MAX_IPOD_FILE_LEN) {
#if DEBUG_IPOD_WORD_FILE
			NSLog(@"Max file length exceeded, branching file");
#endif
			
			if(_fileType == MABVCardContactFile && [pages indexOfObject:data] != [pages count] - 1) {
				//if there is still more pages, advance to the next page
				data = [pages objectAtIndex:[pages indexOfObject:data] + 1];
			} else {
				//create the branch
				branch = [[iPodWordFile alloc] initWithWords:_words];
				[branch setOptions:_options];
						
				[tempStr release];
				break;
			}
		}
		
		//NSLog(@"Words: %@", [[_words objectAtIndex:a] allWords]);
		
		[lastWord release];
		lastWord = [[tempWord word] retain];
		
		[data appendString:tempStr];
		[tempStr release];
		[_words removeObjectAtIndex:0];
		l--;
	}
	
	[self setToWord:lastWord];
	[lastWord release];

	/*
	 The following are reported to be the fastest encodings
	 NSUnicodeStringEncoding
	 NSMacOSRomanStringEncoding
	 
	 Unicode isn't an options because of its size, and MacOS roman is stupid, so we'll just stick w ASCII.
	 Consider using UFT-8 in the future
	 */
	if([data length] != 0) {
		NSData *content;
		NSString *filename;
		
		if(_fileType == MABPlainTextFile) {
			content = [data dataUsingEncoding:ENCODING allowLossyConversion:YES];
			filename = [NSString stringWithFormat:@"%@/%@", path, [self title]];
		} else {//vcard
			/*
			 The iPod wont let your Vcards have arbitrarly labelled addresses.
			 Even if you specify type=WORK & type=HOME work will only show up.
			 The iPod totally disregards the X-ABLabel replaces it with "Work Address"
			 
			 Any field for iPod's contact (address and note are the only currently tested) holds about 2010 characters
			 */
			
			NSArray *addressTypeList = [NSArray arrayWithObjects:@"HOME", @"WORK", nil]; /* type values for contact information... doesn't matter which you use though */
			NSMutableString *tempContent = [NSMutableString string];
			tempContent = [NSMutableString stringWithFormat:@"%@%@%@%@", VCARD_HEADER, _prefix, [self title], VCARD_NAME_END];

			int a = 0, l = [pages count];
			for(; a < l; a++) {
				if(a == 0) {
					[tempContent appendFormat:VCARD_PAGE_TEMPLATE, [addressTypeList objectAtIndex:a], [pages objectAtIndex:a], [NSString stringWithFormat:@"Page %i", a]];
				} else if(a == 1) {
					[tempContent appendFormat:VCARD_NOTE, [pages objectAtIndex:a]];
				}
			}
			
			[tempContent appendString:VCARD_FOOTER];
			
			content = [tempContent dataUsingEncoding:ENCODING allowLossyConversion:YES];
			filename = [NSString stringWithFormat:@"%@/%@.vcf", path, [self title]];
		}
		
		if(![fm createFileAtPath:filename
						contents:content
					  attributes:nil]) {
			NSLog(@"Error creating file at %@", filename);
		}
	}
	#if DEBUG_IPOD_WORD_FILE
	else if {
		NSLog(@"0 file length!");
	}
	#endif

	[data release];
	[pool release];

	//leave the branch processing to the end so we get the other file out of the
	//way and freed first to improve performance
	if(branch) {//if we have a branch to process
		[branch writeFileToPath:path];
		[branch release];
	}
}

//------------------------------
//		Setter & Getters
//-----------------------------
-(NSString *) title {
	return [NSString stringWithFormat:@"%@-%@", _fromWord, _toWord];
}

-(void) setFromWord:(NSString *)w {
	[w retain];
	[_fromWord release];
	_fromWord = w;
	
	//check for really long words, they make the filename on the ipod too long
	if([_fromWord length] > MAX_TITLE_WORD_LEN) {//_fromWord is the same as the 'w' argument in this case
		_fromWord = [[_fromWord substringToIndex: MAX_TITLE_WORD_LEN] retain];
		[w release]; //we dont need the original title anymore
	}
}

-(void) setToWord:(NSString *)w {
	[w retain];
	[_toWord release];
	_toWord = w;
	
	//check for really long words, they make the filename on the ipod too long
	if([_toWord length] > MAX_TITLE_WORD_LEN) {//_fromWord is the same as the 'w' argument in this case
		_toWord = [[_toWord substringToIndex: MAX_TITLE_WORD_LEN] retain];
		[w release]; //we dont need the original title anymore
	}
	
}

- (void) setWords:(NSArray *)a {
	[a retain];
	
	[_words release];
	_words = [a mutableCopy];
	
	[a release];
}

- (void) setOptions:(NSDictionary *)dict {
	extern BOOL MABWordUseChatSlang;
	id temp;
	
	if((temp = [dict valueForKey:PHRASE_KEY]) == nil) {
		_phrases = NO;
	} else {
		_phrases = [temp boolValue];	
	}
	
	if((temp = [dict valueForKey:MIN_WORD_LEN_KEY]) == nil) {
		_minWordLen = DEFAULT_MIN_WORD_LEN;
	} else {
		_minWordLen = [temp intValue];
	}
	
	if((temp = [dict valueForKey:MAX_WORD_LEN_KEY]) == nil) {
		_maxWordLen = DEFAULT_MAX_WORD_LEN;
	} else {
		_maxWordLen = [temp intValue];
	}	
	
	if((temp = [dict valueForKey:HYPEN_WORD_KEY]) == nil) {
		_hyphenatedWords = NO;	
	} else {
		_hyphenatedWords = [temp boolValue];
	}
	
	if((temp = [dict valueForKey:NOUNS_KEY]) == nil) {
		_nouns = NO;	
	} else {
		_nouns = [temp boolValue];
	}
	
	if((temp = [dict valueForKey:APOSTROPHES_KEY]) == nil) {
		_apostrophes = NO;	
	} else {
		_apostrophes = [temp boolValue];
	}
	
	if((temp = [dict valueForKey:DEF_VARIATIONS_KEY]) == nil) {
		_definitionVariations = NO;
	} else {
		_definitionVariations = [temp boolValue];
	}
	
	if((temp = [dict valueForKey:CHAT_SLANG_KEY]) == nil) {
		_useChatSlang = MABWordUseChatSlang = NO;
	} else {
		_useChatSlang = MABWordUseChatSlang = [temp boolValue];
	}
	
	if(isEmpty(temp = [dict valueForKey:FILE_PREFIX_KEY])) {
		_prefix = @"";
	} else {
		_prefix = [temp retain];
	}
	
	if((temp = [dict valueForKey:FILE_TYPE_KEY]) == nil) {
		_fileType = MABPlainTextFile;
	} else {
		_fileType = [temp intValue];
	}
	
	//save the dict for branching
	[dict retain];
	[_options release];
	_options = dict;
}

- (MABFileType) fileType {
    return _fileType;
}

- (void) setFileType:(MABFileType)fileType {
    _fileType = fileType;
}

@end


