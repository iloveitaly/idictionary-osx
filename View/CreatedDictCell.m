//
//  CreatedDictCell.m
//  iDictionary
//
//  Created by Michael Bianco on 4/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "CreatedDictCell.h"
#import "DictRep.h"
#import "shared.h"

#define PADDING 2.0;

@implementation CreatedDictCell
-(void) dealloc {
	[_miniText release];
	[_image release];
	[super dealloc];
}

-(id) copyWithZone:(NSZone *)zone {
	[_image retain];
	[_miniText retain];
	return [super copyWithZone:zone];
}

- (NSColor *)textColor {
	if (_cFlags.highlighted && [NSApp keyWindow] == [[self controlView] window])
        return [NSColor textBackgroundColor];
    else
        return [super textColor];
}

-(void) drawInteriorWithFrame:(NSRect)aRect inView:(NSView *)controlView {
	//NSLog(@"Attributed string value %@", [self attributedStringValue]);
	aRect.origin.y += PADDING; //add some padding on the top
	
	NSMutableAttributedString *dictName = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]];
	NSRect imageRect = aRect;
	NSRect textRect = aRect;
	//NSLog(@"%@", dictName);
	//NSLog(@"%@", dictOptions);
	
	//draw the image
	imageRect.size = [_image size];
	[_image setFlipped:[controlView isFlipped]];
	[_image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	
	//resize the rect to make up for the image
	textRect.origin.x += imageRect.size.width + PADDING;
	textRect.size.width -= imageRect.size.width;
	
	//draw the main text
	[dictName drawInRect:textRect];
	[dictName release];	
	
	//draw the mini title
	textRect.origin.y += 17; //we want the little text to appear a little below the middle
	[[self attributedMiniText] drawInRect:textRect];	
}

-(void) setObjectValue:(id)value {
	if(!value) return; //skip nil
	
	if([value isMemberOfClass:[DictRep class]]) {
		[super setObjectValue:[value name]];
		[self setMiniText:[value infoString]];
	} else {
		//NSLog(@"Value? %@", value);
	}
}

-(NSImage *) image {
	return _image;
}

-(void) setImage:(NSImage *) img {
	[img retain];
	[_image release];
	_image = img;
}

-(NSAttributedString *) attributedMiniText {
	NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	NSColor *textColor = (_cFlags.highlighted && [NSApp keyWindow] == [[self controlView] window])? [NSColor alternateSelectedControlTextColor] : [NSColor grayColor];
	NSDictionary *miniTextAttributes = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont messageFontOfSize:10.0], textColor, paraStyle, nil]
																   forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, NSParagraphStyleAttributeName, nil]];
	NSAttributedString *attributedMiniText = [[NSAttributedString alloc] initWithString:_miniText attributes:miniTextAttributes];
	[paraStyle release];
	
	return [attributedMiniText autorelease];
}

-(NSString *) miniText {	
	return _miniText;
}

-(void) setMiniText:(NSString *)str {
	[str retain];
	[_miniText release];
	_miniText = str;
}

@end
