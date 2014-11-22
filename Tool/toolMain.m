#import <Foundation/Foundation.h>
#import <stdio.h>
#import <unistd.h>

#import "toolConstants.h"
#import "iPodWordFile.h"
#import "MABDictionary.h"
#import "MABWord.h"
#import "shared.h"

//argv[1] = letter to get all words for, is in upper case. argv[2] = path to put all the files.
int main(int argc, char *argv[]) {
	if(argc != 3) {//the correct amount of arguments wasn't specified
#if TOOL_DEBUG
		NSLog(@"Invalid number of arguments");
#endif
		return 1;
	}

	NSAutoreleasePool *pool = [NSAutoreleasePool new], *pool2;
	
	//get the slow creation pref
	BOOL slowCreation = NO;
	if(read(STDIN_FILENO, &slowCreation, sizeof(BOOL)) < 1) {
#if TOOL_DEBUG
		NSLog(@"Unable to read slow creation pref");
#endif
		return 1;
	} else if(slowCreation) {
		setpriority(PRIO_PROCESS, 0, PRIO_MAX); //set this process to the highest (slowest) priority
	}
	
	//read the index of the dictionary to use for processing
	int dictIndex;
	if(read(STDIN_FILENO, &dictIndex, sizeof(int)) < 1) {
#if TOOL_DEBUG
		NSLog(@"Unable to read dictionary index");
#endif
		return 1;
	}
	
#if TOOL_DEBUG
	NSLog(@"Index of dictionary is %i", dictIndex);
#endif
	
	//get the NSDictionary written into stdin
	NSFileHandle *handle = [[NSFileHandle alloc] initWithFileDescriptor:STDIN_FILENO];
	NSDictionary *options = [NSKeyedUnarchiver unarchiveObjectWithData:[handle readDataToEndOfFile]];
	//NSLog(@"Options %@", options);
	
	if(!options) {//if no dictionary was found, exit!
#if TOOL_DEBUG
		NSLog(@"Error getting options from stdin");
#endif
		return 1;
	}
		
	[handle release];
	
	if(!isascii(argv[1][0])) {//check to make sure the char is a ascii char
#if TOOL_DEBUG
		NSLog(@"Target char is not ascii");
#endif
		return 1;
	}
	
	char targetChar = argv[1][0]; //keep the char uppercase for path construction
	NSString *targetDir = [[NSString stringWithCString:argv[2]] stringByAppendingPathComponent:[NSString stringWithFormat:@"%c", targetChar]]; //create the directory that we are going to put files in
	targetChar = tolower(targetChar); //lower the char for dictionary searches
			
	printf("Gathering words starting with %c...", targetChar);
	fflush(stdout); //make sure the output isn't being buffered
	
	//create a pool to autorelease the matchesForString result
	pool2 = [NSAutoreleasePool new];
	
	//start the dictionary creation
	NSArray *results = [[[MABDictionary availableDictionaries] objectAtIndex:dictIndex] matchesForString:[NSString stringWithFormat:@"%c", targetChar]];
	iPodWordFile *file = [[iPodWordFile alloc] initWithWords:results];
	[file setOptions:options];
	
	[pool2 release];
	
	printf("Sorting words starting with %c...", targetChar);
	fflush(stdout);
	
	[file sortWords];
	
	printf("Writing definition files for letter %c...", targetChar);
	fflush(stdout);
	
	[file writeFileToPath:targetDir];
	
	[file release];
	[pool release];
	
	return 0;
}