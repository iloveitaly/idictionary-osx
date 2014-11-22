//
//  CreatedDictionariesController.m
//  iDictionary
//
//  Created by Michael Bianco on 4/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "CreatedDictionariesController.h"
#import "DictionaryCreator.h"
#import "AppSupportController.h"
#import "CreatedDictCell.h"
#import "InterfaceController.h"
#import "NSFileManager+Additions.h"
#import "shared.h"

@implementation CreatedDictionariesController

- (void) windowDidLoad {
	NSCell *cell = [[CreatedDictCell new] autorelease];
	NSImage *image = [DictionaryRepIcon() copy];
	[image setScalesWhenResized:YES];
	[image setSize:NSMakeSize(32.0, 32.0)];
	[cell setImage:image];
	
	[oMainColumn setDataCell:cell];
	
	[[oMainColumn tableView] setFocusRingType:NSFocusRingTypeNone];
	[[oMainColumn tableView] setTarget:self];
	[[oMainColumn tableView] setDoubleAction:@selector(selectDictionary:)];
	
	[[self window] setExcludedFromWindowsMenu:YES];
}

- (IBAction) revealInFinder:(id)sender {
	NSString *path = [[[oController selectedObjects] objectAtIndex:0] path];
	[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
}

- (IBAction) deleteDictionary:(id)sender {
	NSString *path = [[[oController selectedObjects] objectAtIndex:0] path];
	[[NSFileManager defaultManager] moveToTrash:path];
}

- (IBAction) selectDictionary:(id)sender {
	if(![[oController selectedObjects] count]) return; //then nothing is selected
	
	DictRep *rep = [[oController selectedObjects] objectAtIndex:0];
	[[DictionaryCreator sharedCreator] selectDictionary:rep];
}

- (AppSupportController *) sharedAppSupportController {
	//NSLog(@"%@", [[AppSupportController sharedController] createdDictionaries]);
	return [AppSupportController sharedController];
}

- (void) setSharedAppSupportController:(AppSupportController *) cnrl {}
@end
