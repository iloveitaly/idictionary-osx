//
//  DictRep.h
//  DictPod
//
//  Created by Michael Bianco on 3/10/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DictRep : NSObject {
	NSDictionary *_properties;
	NSString *_path;
	BOOL _isIncomplete;
	char _pausedState;
}

+(DictRep *) dictRepWithPropertyPath:(NSString *)path;

-(id) initWithPropertyPath:(NSString *)path;

//----------------------------------------------
//	Getter & Setters
//----------------------------------------------
-(NSDictionary *) properties;
-(NSString *) infoString;
-(NSString *) path; //path to the folder which this DictRep represents
-(NSString *) name; //not the same as -[MABDictionary dictionaryName]
-(BOOL) isIncomplete;
-(BOOL) isDemoDictionary;
-(float) percentComplete;
-(char) pausedState;
@end
