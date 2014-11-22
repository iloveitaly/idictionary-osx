//
//  interfaceController.m
//  DPod
//
//  Created by Michael Bianco on 12/31/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "InterfaceController.h"
#import "MABDictionary.h"
#import "OATextWithIconCell.h"
#import "shared.h"

//for the ipod list
#import <sys/param.h>
#import <sys/ucred.h>
#import <sys/mount.h>

NSImage *DictionaryRepIcon(void) {
	static NSImage *icon = nil;
	
	if(!icon) {
		//retrieve an icon to represent the dictionary
		icon = [[NSImage alloc] initWithContentsOfFile:DICT_APP_ICON_PATH];
		if(!icon) icon = [[NSImage alloc] initWithContentsOfFile:DICT_ICON_PATH]; //if we werent able to get the Dictionary.app's icon
		if(!icon) NSLog(@"Unable to get icon!");
	}
	
	return icon;
}
	
@implementation InterfaceController
- (id) init {
	if ((self = [super init]) != nil) {
		_iPodListNeedRefresh = YES;
		
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(volumeMounted:)
																   name:@"NSWorkspaceDidUnmountNotification" 
																 object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(volumeUnmounted:)
																   name:@"NSWorkspaceDidMountNotification"
																 object:nil];
	}
	
	return self;
}

-(void) awakeFromNib {
	[oMainWindow setExcludedFromWindowsMenu:YES];
	
	[oMinWordLength setDelegate:self];
	[oMaxWordLength setDelegate:self];
	
	//set up the table columns data caells
	OATextWithIconCell *cell = [[OATextWithIconCell new] autorelease];
	[cell setDrawsHighlight:NO];
	[cell setImageSize:NSMakeSize(16.0, 16.0)];
	
	[oDictColumn setDataCell:cell];
	[oIPodColumn setDataCell:cell];
	
	//disable sorting
	[[oDictColumn tableView] unbind:@"sortDescriptors"];
	[[oIPodColumn tableView] unbind:@"sortDescriptors"];
	
	//disable the focus ring
	[[oDictColumn tableView] setFocusRingType:NSFocusRingTypeNone];
	[[oIPodColumn tableView] setFocusRingType:NSFocusRingTypeNone];
}

-(void) volumeMounted:(NSNotification *)note {
	_iPodListNeedRefresh = YES;
	[self connectedIPods];
}

-(void) volumeUnmounted:(NSNotification *)note {
	_iPodListNeedRefresh = YES;
	[self connectedIPods];
}


- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error {
	if(control == oMinWordLength) {
		[control setStringValue:[NSString stringWithFormat:@"%i", DEFAULT_MIN_WORD_LEN]];
	} else if(control == oMaxWordLength) {
		[control setStringValue:[NSString stringWithFormat:@"%i", DEFAULT_MAX_WORD_LEN]];
	}
	
	return NO;
}

-(NSArray *) connectedIPods {
	if(_iPodListNeedRefresh) {
		NSMutableArray *ipods = [NSMutableArray array];
		NSFileManager *fm = [NSFileManager defaultManager];
		struct statfs *buf;
		int i, count;
		
		count = getmntinfo(&buf, 0);
		for (i = 0; i < count; i++) {
			if ((buf[i].f_flags & MNT_LOCAL) == MNT_LOCAL) {
				NSString *path = [NSString stringWithUTF8String:buf[i].f_mntonname];
				if ([fm fileExistsAtPath:[path stringByAppendingPathComponent:@"iPod_Control"]]) {
					//resize the icon image
					NSImage *iPodIcon = [[NSWorkspace sharedWorkspace] iconForFile:path];
					[iPodIcon setSize:ICON_SIZE];
					
					[ipods addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[path lastPathComponent], iPodIcon, path, nil]
																 forKeys:[NSArray arrayWithObjects:TITLE_KEY, IMG_KEY, IPOD_PATH_KEY, nil]]];
				}
			}
		}
		
		_iPodListNeedRefresh = NO;
		[self setConnectedIPods:ipods];
	}
	
	return _iPods;
}

-(void) setConnectedIPods:(NSMutableArray *) ar {
	[ar retain];
	[_iPods release];
	_iPods = ar;
}

-(NSArray *) availableDictionaries {	
	NSArray *dicts = [MABDictionary availableDictionaries];
	NSMutableArray *array = [NSMutableArray array];
	MABDictionary *dict;
	NSString *name, *path;
	NSImage *dictIcon = [DictionaryRepIcon() copy];
	
	//resize the image
	[dictIcon setScalesWhenResized:YES];
	[dictIcon setSize:ICON_SIZE]; //if we have a image resize it
	
	int a = 0, c = [dicts count];
	for(; a < c; a++) {
		dict = [dicts objectAtIndex:a];
		name = [dict dictionaryName];
		path = [dict dictionaryPath];
		
		if(dict && name && path) {//make sure we have valid variables	
			[array addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects: name, dictIcon, dict, nil]
														 forKeys:[NSArray arrayWithObjects: TITLE_KEY, IMG_KEY, DICT_KEY, nil]]];
		} else {
			NSLog(@"Name for %@, %@. Path %@", dict, name, path);
		}
	}
	
	[dictIcon release];
	
	return array;
}
@end
