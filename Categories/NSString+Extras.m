//
//  NSString+Extras.m
//  iDictionary
//
//  Created by Michael Bianco on 4/29/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSString+Extras.h"

@implementation NSString (Extras)
- (NSString *) trimWhiteSpace {
	
	NSMutableString *s = [[self mutableCopy] autorelease];
	
	CFStringTrimWhitespace ((CFMutableStringRef) s);
	
	return (NSString *) [[s copy] autorelease];
} /*trimWhiteSpace*/
@end
