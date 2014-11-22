//
//  DictRep.m
//  DictPod
//
//  Created by Michael Bianco on 3/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "DictRep.h"
#import "DictionaryCreator.h"
#import "shared.h"

@implementation DictRep
+(DictRep *) dictRepWithPropertyPath:(NSString *)path {
	return [[[DictRep alloc] initWithPropertyPath:path] autorelease];
}

-(id) initWithPropertyPath:(NSString *)path {
	if(self = [self init]) {
		_properties = [[NSDictionary alloc] initWithContentsOfFile:path];
		_path = [[path stringByDeletingLastPathComponent] retain];
		_isIncomplete = NO;
		
		NSString *pausePath = [_path stringByAppendingPathComponent:DICT_PAUSE_FILE_NAME];
		NSFileManager *fm = [NSFileManager defaultManager];
		
		if([fm fileExistsAtPath:pausePath]) {
			NSString *pausedFile = [NSString stringWithContentsOfFile:pausePath
															 encoding:NSASCIIStringEncoding
																error:nil];
			
			if(!pausedFile) {
				NSLog(@"Error getting state file");
			}
			
			_pausedState = (char) [pausedFile characterAtIndex:0];
			_isIncomplete = YES;
		}
	}
	
	return self;
}

-(BOOL) isEqual:(id)ob {
	if([super isEqual:ob]) {
		return YES;
	} else if([ob isMemberOfClass:[self class]]) {
		return [_properties isEqualToDictionary:[ob properties]];
	} else if([ob isKindOfClass:[NSDictionary class]]) {
		return [_properties isEqualToDictionary:ob];
	}

	return NO;
}

-(void) dealloc {
	[_properties release];
	[_path release];
	[super dealloc];
}

//----------------------------------------------
//	Getter & Setters
//----------------------------------------------

-(NSDictionary *) properties {
	return _properties;	
}

#define checkKey(k, s, s1) \
if([[_properties valueForKey:k] boolValue]) { \
	if([str length]) \
		[str appendString:s]; \
	else \
		[str appendString:s1]; \
}


- (NSString *) infoString {
	NSMutableString *str = [NSMutableString string];
	
	checkKey(CHAT_SLANG_KEY, @", Chat slang", @"Chat slang");
	checkKey(PHRASE_KEY, @", Phrases", @"Phrases");
	checkKey(ABBREV_KEY, @", Abbreviations", @"Abbreviations");
	checkKey(HYPEN_WORD_KEY, @", Hyphenated words", @"Hyphenated words");
	checkKey(NOUNS_KEY, @", Proper nouns", @"Proper nouns");
	checkKey(APOSTROPHES_KEY, @", Contractions", @"Contractions");
	checkKey(DEF_VARIATIONS_KEY, @", Word variations", @"Word variations");
	
	if([str length])
		[str appendString:@". "];
	
	if(!isEmpty([_properties valueForKey:FILE_PREFIX_KEY])) 
		[str appendString:[NSString stringWithFormat:@"Contact file name prefix %@. ", [_properties valueForKey:FILE_PREFIX_KEY]]];
	
	if([[_properties valueForKey:FILE_TYPE_KEY] intValue] == MABPlainTextFile) [str appendString:@"Note file format. "];
	else [str appendString:@"Contact file format. "];
	
	int min = [[_properties valueForKey:MIN_WORD_LEN_KEY] intValue], max = [[_properties valueForKey:MAX_WORD_LEN_KEY] intValue];
	[str appendString:[NSString stringWithFormat:@"Min word length %i, max word length %i. ", min, max]];
	
	if(_isIncomplete) {
		//NSLog(@"Difference %c %i", _pausedState, _pausedState - 'A');
		[str appendString:[NSString stringWithFormat:@"%.2f%% percent complete.", [self percentComplete]]];
	}
	
	return str;
}

- (NSString *) path {
	return _path;	
}

- (NSString *) name {
	return [NSString stringWithFormat:@"%@%@", _isIncomplete? @"Incomplete " : @"", [_properties valueForKey:DICT_USED_KEY]];
}

- (BOOL) isIncomplete {
	return _isIncomplete;	
}

- (BOOL) isDemoDictionary {
	return [[_properties valueForKey:DEMO_VERSION_KEY] boolValue];
}

- (float) percentComplete {
	return ((_pausedState - 'A')/(float)([self isDemoDictionary] ? LETTER_COUNT_FREE_VERSION : LETTER_COUNT)) * 100;
}

- (char) pausedState {
	return _pausedState;
}
@end
