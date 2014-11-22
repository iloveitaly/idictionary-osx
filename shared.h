#define HIDDEN_FILES /* the prop files, license files, and all other 'meta data' files that iDictionary uses are hidden with this defined */
#define HIDDEN_LICENSE_FUNCTIONS /* use funky names for license related functions and use define to map the old names to the new names */

#define OPEN_URL(urlString) [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]]
#define APP_VERSION [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]

#define MAX_FREE_VERSION_LETTER_LC 'd'
#define MAX_FREE_VERSION_LETTER_UC 'D'

#define LETTER_COUNT_FREE_VERSION (MAX_FREE_VERSION_LETTER_LC - 'a' + 1)
#define LETTER_COUNT 26

#define DEFAULT_MIN_WORD_LEN 2
#define DEFAULT_MAX_WORD_LEN 0

//== options keys for the dictionary property list ==

//key used for the filtering options
#define PHRASE_KEY @"allowPhrase"
#define HYPEN_WORD_KEY @"hyphenKey"
#define MIN_WORD_LEN_KEY @"minWordLen"
#define MAX_WORD_LEN_KEY @"maxWordLen"
#define NOUNS_KEY @"nouns"
#define APOSTROPHES_KEY @"apostrophes"
#define ABBREV_KEY @"abbreviations"
#define DEF_VARIATIONS_KEY @"dupeDefinitions"
#define CHAT_SLANG_KEY @"chatSlang"
#define FILE_TYPE_KEY @"fileType"				/* either 0 or 1, representing Note files or Contact files */

//other keys
#define DICT_USED_KEY @"dict"			/* the key representing the dictionary that was used to create the iPod dictionary */
#define VERSION_KEY @"version"			/* the version of iDictionary used to create this dictionary */
#define APP_NAME_KEY @"appName"			/* name of the application, this was important when there was iDictionary & iDictionary Lite */
#define DEMO_VERSION_KEY @"demo"		/* BOOL if this dictionary was created while the program was unregistered */
#define FILE_PREFIX_KEY @"filePrefix"	/* prefix for the contact files to make sure there's a difference between the dictionary & thesaurus in the iPod */

//====================================================

#ifdef __OBJC__
static inline BOOL isEmpty(id thing) {
    return thing == nil
	|| ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
	|| ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}
#endif