/*
 *  testDictImplementation.h
 *  DictPod
 *
 *  Created by Michael Bianco on 1/28/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <ApplicationServices/ApplicationServices.h>
#import <Cocoa/Cocoa.h>

void testDict(void);
void testDict2(void);
NSString * extractDef(CFStringRef definitionData);

//look in /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/CarbonCore.framework/Versions/A/Headers/ for carbon data types