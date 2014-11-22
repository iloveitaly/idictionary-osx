#import <Cocoa/Cocoa.h>

#import "RegistrationHandling.h"
#import "shared.h"
#import "iPodWordFile.h"

#define PROGRESS_STEPS ((IsRegistered() ? LETTER_COUNT : LETTER_COUNT_FREE_VERSION) * 3.0)
#define PROGRESS_INCR 1.0
#define MAX_IPOD_FILES 1000

#define FILE_HANDLE_DATA_KEY @"NSFileHandleNotificationDataItem"

#ifdef HIDDEN_FILES
#define DICT_PROP_FILE_NAME @".props.plist"
#define DICT_PAUSE_FILE_NAME @".pause_state"
#else
#define DICT_PROP_FILE_NAME @"props.plist"
#define DICT_PAUSE_FILE_NAME @"pause_state"
#endif

#define IPOD_NOTES_FOLDER @"Notes"
#define IPOD_CONTACT_FOLDER @"Contacts"
#define DICT_BUY_NOW_NAME @"Buy iDictionary"

#define DICT_CNTRL_DEBUG 0
#define DICT_HELPER_RECORD_TIME 0

/*
 Dictionary Creation File Stats:
 1rst: ~976 files. Date 1/12/05. Min word length at 2, max word length at 0.
 2nd: ~941. Date 1/22/06. Min word length at 2, max word length at 0.
 3rd: ~1024. Date 1/22/06. Min word length at 2, max word length at 0. Alternate definitions turned on. Later found two whole letters missing (H & V).
 4th: ~1045. Date 2/23/06. Min word length at 2, max word length at 0. Alternate definitions turned on with prefix finder.
 5th: ~1081. Date 3/07/06. Min word length at 2, max word length at 0. Alternate definitions turned on with prefix finder. New MABDictionary implemenation
 6th: ~1051. Date 3/07/06. Min word length at 2, max word length at 0. Alternate definitions turned on with prefix finder. New MABDictionary implemenation
 
 Thesaurus Creation file Stats:
 1rst: ~461 files. Date 03/08/06. Min word length at 2, max word length at 0. Alternate definitions turned on with prefix finder.
 */

@class MABDictionary, DictRep;

@interface DictionaryCreator : NSObject {
	BOOL _isCreatingDictionary;
	char _currLetter;
	int _dictIndex;
	MABFileType _fileType;
	
	NSTask *_currTask;
	NSString *_targetPath, *_copyTargetPath, *_propertiesPath;
	NSFileHandle *_currReadHandle;
	NSDictionary *_options;
	MABDictionary *_dict;
	
#if DICT_HELPER_RECORD_TIME
	time_t _startTime;
	time_t _totalTime;
#endif
	
	IBOutlet NSWindow *oProgressSheet, *oMainWindow;
	IBOutlet NSTextField *oStatus, *oMinWordLen, *oMaxWordLen, *oPrefix;
	IBOutlet NSProgressIndicator *oProgress;
	IBOutlet NSArrayController *oIPodController, *oDictionariesController;
	IBOutlet NSButton *oPhrase, *oAbbrev, *oHyphen, *oNoun, *oContractions, *oDefinitionVariations, *oChatSlang, *oSheetButton;
	IBOutlet NSPopUpButton *oFileType;
}

+(DictionaryCreator *) sharedCreator;

//----------------------------------------------
//		Action Methods
//----------------------------------------------
- (IBAction) createDictionary:(id)sender;
- (IBAction) stopCreation:(id)sender;
- (IBAction) closeSheet:(id)sender;
- (void) selectDictionary:(DictRep *) rep;

//----------------------------------------------
//	Notification Methods For NSTask Stuff
//----------------------------------------------
- (void) helperClosed:(NSNotification *) note;
- (void) helperData:(NSNotification *)note;

//----------------------------------------------
//	Notification Methods For UI Stuff
//----------------------------------------------
- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;

//----------------------------------------------
//	Notification For NSFileManager
//----------------------------------------------
- (BOOL) fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo;
- (void) fileManager:(NSFileManager *)manager willProcessPath:(NSString *)path;

//----------------------------------------------
//	Other Notifications
//----------------------------------------------
- (void) applicationRegistered:(NSNotification *)note;

//-----------------------
//		Getter & Setters
//-----------------------
- (BOOL) isCreatingDictionary;
- (void) setIsCreatingDictionary:(BOOL) b;
- (NSDictionary *) options;
- (void) setOptions:(NSDictionary *)options;
- (NSString *) targetPath;
- (void) setTargetPath:(NSString *)path;
- (NSString *)copyPath;
- (void) setCopyPath:(NSString *)path;
- (NSString *) propertiesPath;
- (void) setPropertiesPath:(NSString *)path;
- (MABFileType) fileType;
- (void) setFileType:(MABFileType)fileType;
@end
