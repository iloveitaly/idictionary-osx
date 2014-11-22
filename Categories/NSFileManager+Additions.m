//
//  NSFileManager+Additions.m
//  XASH
//
//  Created by Michael Bianco on 4/5/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager+Additions.h"


@implementation NSFileManager (IsDirectory)
- (BOOL) pathIsDirectory:(NSString *)path {
	BOOL isDir = NO;
	
	if(![self fileExistsAtPath:path isDirectory:&isDir])
		return NO;
	
	return isDir;
}

- (BOOL) moveToTrash:(NSString *)path {
	int tag;
	return [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
														source:[path stringByDeletingLastPathComponent]
												   destination:@""
														 files:[NSArray arrayWithObject:[path lastPathComponent]]
														   tag:&tag] && tag == 0;
}
@end
