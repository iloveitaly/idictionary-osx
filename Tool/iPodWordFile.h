#import <Cocoa/Cocoa.h>

#define DEBUG_IPOD_WORD_FILE 0

#define AVG_ARRAY_SIZE 500
#define MAX_DEFINITION_LENGTH 10000
#define ARRAY_RELEASE_STACK_LENGTH 1000
#define ENCODING NSASCIIStringEncoding
#define MAX_IPOD_FILE_LEN (_fileType == MABPlainTextFile ? MAX_IPOD_PLAIN_TEXT_LEN : MAX_IPOD_CONTACT_FIELD_LEN) /* this macro is only used in iPodWordFile.m */
#define MAX_IPOD_PLAIN_TEXT_LEN (1024 * 4) /* 4kb */
#define MAX_IPOD_CONTACT_FIELD_LEN (1050 * 2) /* a little more than 2kb */
#define MAX_TITLE_WORD_LEN 9 /* two words are used in the title plus a '-'. The iPod screen can show ~20 characters, 9*2+1 = 19 */

//vcard template
#define VCARD_HEADER @"BEGIN:VCARD\nVERSION:3.0\nN:;"
#define VCARD_NAME_END @";;;\n"
#define VCARD_PAGE_TEMPLATE @"item1.ADR;type=%@;type=pref:;;%@;;;;\nitem1.X-ABLabel:%@\nitem1.X-ABADR:us\n" /* format item 1 is address identifier (WORK, HOME), format item 3 is page name/number, format item 2 is dictionary data */
#define VCARD_NOTE @"NOTE:%@\n"
#define VCARD_FOOTER @"END:VCARD"

@class MABWord;

typedef enum {
	MABPlainTextFile = 0, 
	MABVCardContactFile = 1
} MABFileType;

@interface iPodWordFile : NSObject {
	NSString *_fromWord, *_toWord, *_prefix;
	NSMutableArray *_words;
	NSDictionary *_options;
	MABFileType _fileType;
	
	BOOL _phrases, _hyphenatedWords, _nouns, _abbreviations, _apostrophes, _slashes, _definitionVariations, _useChatSlang;
	int _minWordLen, _maxWordLen, _vcardPageCount;
}

//------------------------------
//		Initializers
//-----------------------------
-(id) initWithWord:(MABWord *)w;
-(id) initWithWords:(NSArray *)a;

//------------------------------
//		Action Methods
//-----------------------------
-(void) addWord:(MABWord *)w;
-(void) sortWords;
-(void) writeFileToPath:(NSString *)path;

//------------------------------
//		Setter & Getters
//-----------------------------
-(NSString *) title;
-(void) setFromWord:(NSString *)w;
-(void) setToWord:(NSString *)w;
-(void) setWords:(NSArray *)a;
-(void) setOptions:(NSDictionary *)dict;
-(MABFileType) fileType;
-(void) setFileType:(MABFileType)fileType;
@end
