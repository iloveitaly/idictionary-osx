/*
 *  classDeconstruct.c
 *  DictPod
 *
 *  Created by Michael Bianco on 1/28/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import "classDeconstruct.h"

#import </usr/include/objc/objc-class.h>
#import </usr/include/objc/Protocol.h>
#import <Foundation/Foundation.h>

void DeconstructClass(Class aClass) {
    struct objc_class *class = aClass;
    const char *name = class->name;
    int k;
    void *iterator = 0;
    struct objc_method_list *mlist;
	
    NSLog(@"Deconstructing class %s, version %d",
          name, class->version);
    NSLog(@"%s size: %d", name,
          class->instance_size);
    if (class->ivars == nil)
        NSLog(@"%s has no instance variables", name);
    else
	{
        NSLog(@"%s has %d ivar%c", name,
              class->ivars->ivar_count,
              ((class->ivars->ivar_count == 1)?' ':'s'));
        for (k = 0;
             k < class->ivars->ivar_count;
             k++)
            NSLog(@"%s ivar #%d: %s", name, k,
                  class->ivars->ivar_list[k].ivar_name);
	}
    mlist = class_nextMethodList(aClass, &iterator);
    if (mlist == nil)
        NSLog(@"%s has no methods", name);
    else do
	{
		for (k = 0; k < mlist->method_count; k++)
		{
			NSLog(@"%s implements %@", name,
				  NSStringFromSelector(mlist->method_list[k].method_name));
		}
	}
        while ( mlist = class_nextMethodList(aClass, &iterator) );
	
    if (class->super_class == nil)
        NSLog(@"%s has no superclass", name);
    else
	{
        NSLog(@"%s superclass: %s", name, class->super_class->name);
        DeconstructClass(class->super_class);
	}
}
