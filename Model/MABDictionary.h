#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

#define DICT_SEARCH_BEGINNING kDCMFindMethodBeginningMatch /* returns all words containing/beggining with the specified search string*/
#define DICT_SEARCH_EQ kDCMFindMethodExactMatch /* only returns words that are the exact same as the search string */

#define DICT_SEARCH_PATH @"/Library/Dictionaries" /* the path that the dictionaries are at. iDictionary searches this path and ~/Library/Dictionaries */
#define DICT_EXTENSION @"dict" /* extension of the dictionary package */

#define DICT_NAME_KEY @"DSDictionaryName"
#define DICT_TYPE_KEY @"DSDictionaryCategoryName"

#define DICT_TYPE_DICT_IDENTIFIER @"Dictionary"
#define DICT_TYPE_THESAUR_IDENTIFIER @"Thesaurus"

#define DEBUG_DICTIONARY 0

/*
DSDictionaryName
DSDictionaryCategoryName
DSDictionaryManufacturerName
DSDictionaryCopyright
*/

/*
 BASH command to count the occurances of a word in a bunch of files:
 
 out=`grep -cRE "and|are|you|two|ok|see" /Users/Mike/Desktop/ipod/ | grep -oE "[1-9][0-9]?$" | sed -E 'N;s/([0-9]){1,2}\n([0-9]){1,2}/+\1+\2/g'`;
 out=${out:1};
 echo $out | sed 's/ //g' | bc
 */

enum {
	MABDictionaryType = 1,
	MABThesaurusType
};

@class MABWord;

@interface MABDictionary : NSObject {
	NSDictionary *_dictProps;
	NSString *_dictPath, *_dictName;
	DCMDictionaryID _dictID;
	DCMDictionaryRef _dictRef;
	int _dictType;
	
	ItemCount _totalRecords; //unsigned int 32
	BOOL _isOpened;
}
//-----------------------
//		Class Methods
//-----------------------
+(NSArray *) availableDictionaries; //returns an array of DSDictionaries

-(id)initWithPath:(NSString *)path andID:(DCMDictionaryID)dict;

#ifndef DICTIONARY_GUI
-(NSMutableArray *) matchesForString:(NSString *)searchString; //returns an array of DictionaryRecord objects
-(MABWord *) definitionForWord:(NSString *)searchString; //returns nil if no definition can be found
-(NSMutableArray *) _matchesForString:(NSString *)searchString limit:(NSNumber *)limit skipCount:(NSNumber *)skip method:(unsigned int) method;
#endif

//----------------------------
//		Getter & Setter
//----------------------------
-(BOOL) isOpened;
-(void) setIsOpened:(BOOL)b;
-(ItemCount) totalRecords;
-(NSString *) dictionaryName;
-(NSString *) dictionaryPath;
-(NSString *) dictionaryCategory;
-(int) dictionaryType;
-(DCMDictionaryRef) dictionaryRef;
@end
