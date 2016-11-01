#import "NSStringAdditions.h"

@implementation NSString (NSStringAdditions)

+ (NSString *)stringByGeneratingUUID {
    CFUUIDRef UUIDReference = CFUUIDCreate(nil);
    CFStringRef temporaryUUIDString = CFUUIDCreateString(nil, UUIDReference);
    
    CFRelease(UUIDReference);
#if ! __has_feature(objc_arc)
    return [NSMakeCollectable(temporaryUUIDString) autorelease];
#else
    return (__bridge_transfer NSString*)temporaryUUIDString;
#endif
}

@end
