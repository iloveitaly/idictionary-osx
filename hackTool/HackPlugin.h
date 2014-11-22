//
//  HackPlugin.h
//  iDictionary
//
//  Created by Michael Bianco on 2/9/07.
//  Copyright 2007 Prosit Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

typedef OSStatus (*dcmFunct)(DCMDictionaryRef dictionaryRef,DCMFieldTag keyFieldTag,ByteCount keySize,ConstLogicalAddress keyData,DCMFindMethod findMethod,ItemCount preFetchedDataNum,DCMFieldTag preFetchedData[],ItemCount skipCount,ItemCount maxRecordCount,DCMFoundRecordIterator * recordIterator);
dcmFunct oldDCMAccess;
OSStatus newDCMFindRecords (
							DCMDictionaryRef dictionaryRef,
							DCMFieldTag keyFieldTag,
							ByteCount keySize,
							ConstLogicalAddress keyData,
							DCMFindMethod findMethod,
							ItemCount preFetchedDataNum,
							DCMFieldTag preFetchedData[],
							ItemCount skipCount,
							ItemCount maxRecordCount,
							DCMFoundRecordIterator * recordIterator);

@interface HackPlugin : NSObject {

}

+ (void) loadPlugin;

@end
