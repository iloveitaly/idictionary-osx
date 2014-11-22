#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

#define DEBUG_MAB_WORD 0
#define RELEASE_DEF_DATA_EARLY 1 /* release _definitionData after -[MABWord shortDefinition] is called on the object */

#define COMPARE_INDEX 3

@class MABDictionary;
 
@interface MABWord : NSObject {
	MABDictionary *_dictRef;
	BOOL _noDefinition;
	NSString *_shortDefinition, //extracted dictionary
			 *_definitionData,	//full XML definition data
			 *_wordKey,			//the word this MABWord object represents, used to retrieve data in the DCMGetFieldData()
			 *_word;			//the value of the 'dshw' key
	NSMutableArray *_otherWords;
	char _wordSeperator;
}
//-----------------------
//		Class Methods
//-----------------------
+(MABWord *) wordWithWord:(NSString *)word andDictionary:(MABDictionary *)dict;

//-----------------------
//		Initalizers
//-----------------------
-(id) initWithWord:(NSString *)word andDictionary:(MABDictionary *)dict;

//-----------------------
//		Action Methods
//-----------------------
-(void) addOtherWord:(MABWord *)w;

//-----------------------
//		Getter & Setter
//-----------------------
-(void) setWordSeperator:(char) c;
-(NSString *) definitionData;
-(NSString *) shortDefinition;
-(NSString *) word;
-(NSString *) allWords;
-(NSString *) _getDataForKey:(DCMFieldTag)targetTag;
@end
