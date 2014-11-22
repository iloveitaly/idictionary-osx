#import <Foundation/Foundation.h>
#import <AGRegex/AGRegex.h>
#import <unistd.h>

#import "MABDictionary.h"
#import "MABWord.h"
#import "shared.h"

#import "testDict.h"
#import "HackPlugin.h"

int main(int argc, char *argv[]) {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	//MABWord *word = [[[MABDictionary availableDictionaries] objectAtIndex:0] definitionForWord:@"double flat"];
	//AGRegex *regex = [[AGRegex alloc] initWithPattern:@" "],
	//		*extractRegex = [[AGRegex alloc] initWithPattern:@"<o:sense>.*?<o:def>(.*?)</o:def>"],
	//		*findTagRegex = [[AGRegex alloc] initWithPattern:@"<o:SB[^>]*>(.*)</o:SB>"];
	
	//NSString *extr = [[findTagRegex findInString:[word definitionData]] groupAtIndex:1];
	//extr = [[extractRegex findInString:extr] groupAtIndex:1];
	//NSLog(@"RESULT: %@", [regex replaceWithString:@"" inString:[NSString stringWithUTF8String:"a sign (𝄫) placed"]]);
	//return 0;

	[HackPlugin loadPlugin];
	//[[[MABDictionary availableDictionaries] objectAtIndex:0] definitionForWord:@"hello"];
	testDict2();
	NSLog(@"Done!");
	return;

	NSLog(@"MAB Dictionaries %@", [MABDictionary availableDictionaries]);
	NSLog(@"MAB Dict 1 Count %i", [[[MABDictionary availableDictionaries] objectAtIndex:0] totalRecords]);
	NSLog(@"%@", [[[[MABDictionary availableDictionaries] objectAtIndex:1] definitionForWord:@"hi"] definitionData]);
	return 0;

	NSAutoreleasePool *pool2 = [NSAutoreleasePool new];
	
	NSMutableArray *results;
	NSMutableArray *sorted[10000];
	results = [[[[MABDictionary availableDictionaries] objectAtIndex:0] matchesForString:@"a"] retain];
	[pool2 release];

	int a = 0, l = [results count];
	int length, index;
	MABWord *temp, *temp2;
	
	memset(sorted, 0, 10000);
	
	pool2 = [NSAutoreleasePool new];
	
	for(; a < l; a++) {
		if(isEmpty([temp = CFArrayGetValueAtIndex(results, a) shortDefinition])) {
			NSLog(@"Removing word, word %@", CFArrayGetValueAtIndex(results, a));
			
			CFArrayRemoveValueAtIndex(results, a);
			l--;
			a--;
		} else {
			if(!sorted[length = CFStringGetLength([temp shortDefinition])]) {
				sorted[length] = [[NSMutableArray alloc] initWithObjects:temp, nil];
			} else {
				if((index = [sorted[length] indexOfObject:temp]) != NSNotFound) {
					[CFArrayGetValueAtIndex(sorted[length], index) addOtherWord:temp];
					
					//NSLog(@"Duplicate definition found");
					CFArrayRemoveValueAtIndex(results, a);
					l--;
					a--;			
				} else {
					CFArrayAppendValue(sorted[length], temp);
				}
			}
		}
	}

	[pool2 release];
	
	/*for(a = 0, l = [results count]; a < l; a++) {
		//NSLog(@"%i", a);
		pool2 = [NSAutoreleasePool new];
		temp = CFArrayGetValueAtIndex(results, a);
		
		int a2 = a + 1;
		for(; a2 < l; a2++) {
			if([temp2 = CFArrayGetValueAtIndex(results, a2) isEqual:temp]) {
				//NSLog(@"Equal!");
				//NSLog(@"Retain count %i", [temp2 retainCount]);
				
				[temp addOtherWord:temp2];
				[results removeObjectAtIndex:a2];
				temp2 = nil;
				l--;
			}
		}
		
		[pool2 release];
	}*/
	
	NSLog(@"Done!");
	
	[results release];
	[pool release];
	
	//sleep(100);
	
	return 0;	
}
