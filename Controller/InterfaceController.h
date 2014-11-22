#import <Cocoa/Cocoa.h>

//dictionary table view keys
#define TITLE_KEY @"title"
#define DICT_KEY @"dict"
#define IMG_KEY @"img"

//ipod table view keys
#define IPOD_PATH_KEY @"path"
//IMG_KEY, and TITLE_KEY are already defined above

#define DICT_ICON_PATH @"/System/Library/Components/Kotoeri.component/Contents/Support/WordRegister.app/Contents/Resources/Dictionary.icns" /* the green dictionary icon */
#define DICT_APP_ICON_PATH @"/Applications/Dictionary.app/Contents/Resources/Dictionary.icns" /* the Dictionary apps icon */
#define ICON_SIZE NSMakeSize(16.0F, 16.0F)

NSImage *DictionaryRepIcon(void);

@interface InterfaceController : NSObject {
	BOOL _iPodListNeedRefresh;
	NSMutableArray *_iPods;
	
	IBOutlet NSWindow *oMainWindow;
	IBOutlet NSTextField *oMinWordLength, *oMaxWordLength;
	IBOutlet NSTableColumn *oDictColumn, *oIPodColumn;
}

//-----------------------
//	NSWorkspace Notifications
//-----------------------
-(void) volumeMounted:(NSNotification *)note;
-(void) volumeUnmounted:(NSNotification *)note;

//-----------------------
//	Delegate For TextFields
//-----------------------
- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error;

//-----------------------
//	Getter & Setters
//-----------------------
-(NSArray *) connectedIPods;
-(void) setConnectedIPods:(NSMutableArray *) ar;

-(NSArray *) availableDictionaries;
@end
