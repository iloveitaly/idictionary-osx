//
//  CreatedDictCell.h
//  iDictionary
//
//  Created by Michael Bianco on 4/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CreatedDictCell : NSTextFieldCell {
	NSImage *_image;
	NSString *_miniText;
}

-(NSImage *) image;
-(void) setImage:(NSImage *) img;

-(NSAttributedString *) attributedMiniText;
-(NSString *) miniText;
-(void) setMiniText:(NSString *)str;

@end
