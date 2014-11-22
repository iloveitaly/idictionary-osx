#define PREF_KEY_VALUE(x) [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:(x)]
#define PREF_KEY_BOOL(x) [(PREF_KEY_VALUE(x)) boolValue]

#define AUTO_OPEN_MAIN_WINDOW @"autoOpenCreationWindow"
#define SLOW_DICTIONARY_CREATION @"slowCreation"