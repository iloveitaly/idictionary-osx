//
//  HackPlugin.m
//  iDictionary
//
//  Created by Michael Bianco on 2/9/07.
//  Copyright 2007 Prosit Software. All rights reserved.
//

#import "HackPlugin.h"
#import "mach_override.h"

// FSA load plugin command:
//	bund := (NSBundle alloc) initWithPath:'/Volumes/Work/CocoaApps/iDictionary/trunk/build/Debug/TestBundle.bundle'. bund load. (bund classNamed:'HackPlugin') loadPlugin.

char extractCharFromBytes(int bytes, int index) {
	return (bytes & (0xFF << (4 * 2) * index)) >> (4 * 2 * index);
}

char *createStringFromInt(int bytes) {
	char *buff = (char*)malloc(sizeof(char) * 5);
	
	int l = 4;
	while(--l >= 0) {
		*(buff + (3 - l)) = extractCharFromBytes(bytes, l);
		//printf("%c : ", *(buff + (3 - l)));
	}
	
	//printf("\n---\n");
	
	*(buff + 5) = '\0';
	
	return buff;
}


OSStatus newDCMFindRecords(
							DCMDictionaryRef dictionaryRef,
							DCMFieldTag keyFieldTag,
							ByteCount keySize,
							ConstLogicalAddress keyData,
							DCMFindMethod findMethod,
							ItemCount preFetchedDataNum,
							DCMFieldTag preFetchedData[],
							ItemCount skipCount,
							ItemCount maxRecordCount,
							DCMFoundRecordIterator * recordIterator) {
	//NSLog(@"%i : %x : %c", sizeof(DCMFieldTag), 'x', extractCharFromBytes(keyFieldTag, 3));
	char *method = createStringFromInt(keyFieldTag);
	char *fMethod = createStringFromInt(findMethod);
	UniChar *text = (UniChar *) keyData;
		
	NSLog(@"Access Data %p, %s, %i, %p, %s, %i, %p, %i, %i, %p", dictionaryRef, method, keySize, keyData, fMethod, preFetchedDataNum, preFetchedData, skipCount, maxRecordCount, recordIterator);
	OSStatus result = oldDCMAccess(dictionaryRef, keyFieldTag, keySize, keyData, findMethod, preFetchedDataNum, preFetchedData, skipCount, maxRecordCount, recordIterator);
	NSLog(@"Result? %i", result);
	return result;
}

/*
typedef void* (*mallocFunctionPtrType)( size_t );
mallocFunctionPtrType   gMalloc;
void *newMalloc(size_t size);
*/

@implementation HackPlugin
+ (void) loadPlugin {
	NSLog(@"Loaded");
	
	kern_return_t err;
	//NSLog(@"Reference %x", DCMFindRecords);
	
	err = mach_override_ptr((void*)&DCMFindRecords,
							(void*)&newDCMFindRecords,
							(void**)&oldDCMAccess);
	
	//err = mach_override("_DCMFindRecords", NULL, (void*)&newDCMFindRecords, NULL);
	//NSLog(@"Err %i", err == err_cannot_override);
	//err = mach_override("_getuid", NULL, (void*)&newGetuid, (void**)&oldReference);
	//NSLog(@"Err %i", err == err_cannot_override);
	
	/*
	err = mach_override("_malloc", NULL, &newMalloc, (void**)&gMalloc);
	NSLog(@"Err %i", err == err_cannot_override);
	malloc(10);
	*/
	
	NSLog(@"Complete");
}
@end

/*
void *newMalloc(size_t size) {
	printf("DOOO IT!\n");
	return (*gMalloc)(size);
}
*/