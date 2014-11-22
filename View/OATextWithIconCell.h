// Copyright 2001-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-11-18/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OATextWithIconCell.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSTextFieldCell.h>

// This macro ensures that we call [super initialize] in our +initialize (since this behavior is necessary for some classes in Cocoa), but it keeps custom class initialization from executing more than once.
#define OBINITIALIZE \
do { \
	static BOOL hasBeenInitialized = NO; \
        [super initialize]; \
			if (hasBeenInitialized) \
				return; \
					hasBeenInitialized = YES;\
} while (0);


@interface OATextWithIconCell : NSTextFieldCell
{
    NSImage *icon;
	NSSize _iconSize;
	
    struct {
        unsigned int drawsHighlight:1;
        unsigned int imagePosition:3;
        unsigned int settingUpFieldEditor:1;
    } _oaFlags;
}

// API
- (NSImage *)icon;
- (void)setIcon:(NSImage *)anIcon;

- (NSCellImagePosition)imagePosition;
- (void)setImagePosition:(NSCellImagePosition)aPosition;

- (BOOL)drawsHighlight;
- (void)setDrawsHighlight:(BOOL)flag;

-(NSSize) imageSize;
-(void) setImageSize:(NSSize)s;

- (NSRect)textRectForFrame:(NSRect)cellFrame inView:(NSView *)controlView;

@end