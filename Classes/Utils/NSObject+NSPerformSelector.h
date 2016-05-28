//
//  ringmail
//
//  Created by Mike Frager on 2/13/16.
//
//

#ifndef NSObject_NSPerformSelector_h
#define NSObject_NSPerformSelector_h

#import <UIKit/UIKit.h>

@interface NSObject (NSPerformSelector)

+ (id)target:(id)target performSelector:(SEL)selector;
+ (id)target:(id)target performSelector:(SEL)selector withObject:(id)object;
+ (id)target:(id)target performSelector:(SEL)selector withObject:(id)object1 withObject2:(id)object2;

@end

#endif /* NSObject_NSPerformSelector_h */
