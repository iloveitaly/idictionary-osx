//
//  CreatedDictionariesController.h
//  iDictionary
//
//  Created by Michael Bianco on 4/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AppSupportController;

@interface CreatedDictionariesController : NSWindowController {
	IBOutlet NSTableColumn *oMainColumn;
	IBOutlet NSArrayController *oController;
}

-(IBAction) revealInFinder:(id)sender;
-(IBAction) deleteDictionary:(id)sender;
-(IBAction) selectDictionary:(id)sender;

-(AppSupportController *) sharedAppSupportController;
-(void) setSharedAppSupportController:(AppSupportController *) cnrl;
@end
