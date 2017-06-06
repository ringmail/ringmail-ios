#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ChatElementContext : NSObject

- (UIImage*)getImageByID:(NSNumber*)imageID key:(NSString*)key size:(CGSize)maxSize;

@end
