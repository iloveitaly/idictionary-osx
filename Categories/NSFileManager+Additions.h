//
//  NSFileManager+Additions.h
//  XASH
//
//  Created by Michael Bianco on 4/5/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSFileManager (IsDirectory)
-(BOOL) pathIsDirectory:(NSString *)path;
-(BOOL) moveToTrash:(NSString *)path;
@end
